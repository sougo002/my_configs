"""PR の未解決レビューコメントを取得し、スレッドごとに整形して出力する。

GraphQL API を使い、resolved されたスレッドは除外する。
PR 著者のコメントは除外する（セルフコメントは対応不要なため）。

引数を省略した場合は、現ブランチに紐づく PR を自動解決してフォールバックする。

Usage:
    python fetch_comments.py <PR_URL>
    python fetch_comments.py https://github.com/OWNER/REPO/pull/123
    python fetch_comments.py            # 現ブランチのPRにフォールバック
"""

import json
import re
import subprocess
import sys


def parse_pr_url(url: str) -> tuple[str, str, str]:
    """PR URL から owner, repo, pr_number を抽出する。"""
    match = re.match(
        r"https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)", url.strip()
    )
    if not match:
        return "", "", ""
    return match.group(1), match.group(2), match.group(3)


def resolve_current_branch_pr_url() -> str:
    """現ブランチに紐づく PR の URL を取得する。無ければ空文字を返す。"""
    result = subprocess.run(
        ["gh", "pr", "view", "--json", "url", "--jq", ".url"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def fetch_threads_graphql(
    owner: str, repo: str, pr_num: str
) -> tuple[list[dict], list[dict], str]:
    """GraphQL API で未解決のレビュースレッド、レビュー本文、PR著者を取得する。"""
    query = """
    query($owner: String!, $repo: String!, $pr_num: Int!, $cursor: String) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr_num) {
          author { login }
          reviews(first: 100) {
            nodes {
              databaseId
              author { login }
              body
              state
              createdAt
            }
          }
          reviewThreads(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              isResolved
              comments(first: 20) {
                nodes {
                  databaseId
                  author { login }
                  path
                  line
                  originalLine
                  body
                  createdAt
                }
              }
            }
          }
        }
      }
    }
    """

    all_threads: list[dict] = []
    all_reviews: list[dict] = []
    pr_author = ""
    cursor = None

    while True:
        cmd = [
            "gh", "api", "graphql",
            "-f", f"query={query}",
            "-f", f"owner={owner}",
            "-f", f"repo={repo}",
            "-F", f"pr_num={pr_num}",
        ]
        if cursor:
            cmd += ["-f", f"cursor={cursor}"]
        else:
            cmd += ["-f", "cursor="]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error: gh api failed: {result.stderr}", file=sys.stderr)
            sys.exit(1)

        data = json.loads(result.stdout)
        pr_data = data["data"]["repository"]["pullRequest"]
        if not pr_author:
            pr_author = pr_data["author"]["login"]
            all_reviews = pr_data["reviews"]["nodes"]

        threads_data = pr_data["reviewThreads"]
        all_threads.extend(threads_data["nodes"])

        if threads_data["pageInfo"]["hasNextPage"]:
            cursor = threads_data["pageInfo"]["endCursor"]
        else:
            break

    return all_threads, all_reviews, pr_author


def format_output(
    threads: list[dict],
    reviews: list[dict],
    pr_author: str,
    owner: str,
    repo: str,
    pr_num: str,
) -> str:
    lines: list[str] = []
    lines.append(f"## レビューコメント (PR #{pr_num}, {owner}/{repo})")
    lines.append(f"リポジトリ: https://github.com/{owner}/{repo}")
    lines.append(f"PR著者: @{pr_author}")
    lines.append("")

    # レビュー本文（body が空でない、かつ PR 著者以外）
    review_bodies = [
        r for r in reviews
        if r["body"].strip()
        and r["author"]["login"] != pr_author
    ]
    if review_bodies:
        lines.append("### レビュー本文")
        for r in review_bodies:
            author = r["author"]["login"]
            state = r["state"]
            body = r["body"].strip()
            review_id = r["databaseId"]
            lines.append(f"- [review_id: {review_id}] **@{author}** ({state})")
            lines.append(f"  {body}")
            lines.append("")
        lines.append("")

    actionable = []
    skipped_resolved = 0
    skipped_author = 0

    for t in threads:
        if t["isResolved"]:
            skipped_resolved += 1
            continue

        comments = t["comments"]["nodes"]
        if not comments:
            continue

        root = comments[0]

        # PR著者自身のコメントだけで構成されるスレッドはスキップ
        non_author_comments = [
            c for c in comments if c["author"]["login"] != pr_author
        ]
        if not non_author_comments:
            skipped_author += 1
            continue

        # スレッドの先頭（レビュー指摘）は最初の非著者コメント
        # ただし表示はスレッド全体の先頭コメントから
        actionable.append({
            "root": root,
            "replies": comments[1:],
            "first_reviewer_comment": non_author_comments[0],
        })

    if not actionable:
        lines.append("対応が必要なレビューコメントはありません。")
        if skipped_resolved > 0:
            lines.append(f"(resolved {skipped_resolved} 件をスキップ)")
        if skipped_author > 0:
            lines.append(f"(PR著者コメント {skipped_author} 件をスキップ)")
        return "\n".join(lines)

    for i, t in enumerate(actionable, 1):
        root = t["root"]
        reviewer = t["first_reviewer_comment"]
        path = root.get("path", "?")
        line = root.get("line") or root.get("originalLine") or "?"
        author = reviewer["author"]["login"]
        body = reviewer["body"].strip()
        comment_id = reviewer["databaseId"]

        lines.append(f"### スレッド {i} [comment_id: {comment_id}]")
        lines.append(f"- **@{author}** — `{path}:{line}`")
        lines.append(f"- 本文: {body}")

        # 返信を表示（レビュー指摘コメント以降）
        reviewer_idx = next(
            idx for idx, c in enumerate(t["replies"])
            if c["databaseId"] == comment_id
        ) if reviewer["databaseId"] != root["databaseId"] else -1

        reply_start = reviewer_idx + 1 if reviewer_idx >= 0 else 0
        for reply in t["replies"][reply_start:]:
            r_author = reply["author"]["login"]
            r_body = reply["body"].strip()
            lines.append(f"  - 返信 @{r_author}: {r_body}")

        lines.append("")

    summary_parts = []
    if skipped_resolved > 0:
        summary_parts.append(f"resolved {skipped_resolved} 件")
    if skipped_author > 0:
        summary_parts.append(f"PR著者コメント {skipped_author} 件")
    if summary_parts:
        lines.append(f"(スキップ: {', '.join(summary_parts)})")

    return "\n".join(lines)


def main():
    arg = sys.argv[1].strip() if len(sys.argv) >= 2 else ""

    if arg:
        owner, repo, pr_num = parse_pr_url(arg)
        if not owner:
            print(f"URL をパースできませんでした: {arg}")
            print("Claude が手動でコメントを取得します。")
            sys.exit(0)
    else:
        # 引数なし → 現ブランチに紐づく PR にフォールバック
        url = resolve_current_branch_pr_url()
        if not url:
            print("現ブランチに紐づく PR が見つかりませんでした。")
            print("PR URL を指定するか、PR を作成してから再実行してください。")
            sys.exit(0)
        owner, repo, pr_num = parse_pr_url(url)
        if not owner:
            print(f"PR URL をパースできませんでした: {url}")
            sys.exit(0)
        print(f"(現ブランチの PR にフォールバック: {url})")
        print()

    threads, reviews, pr_author = fetch_threads_graphql(owner, repo, pr_num)
    print(format_output(threads, reviews, pr_author, owner, repo, pr_num))


if __name__ == "__main__":
    main()
