"""PR のレビューコメントを取得し、スレッドごとに整形して出力する。

Usage:
    python fetch_comments.py <PR_URL>
    python fetch_comments.py https://github.com/MNTSQ/mntsq-ai-widget/pull/123
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


def fetch_comments(owner: str, repo: str, pr_num: str) -> list[dict]:
    """gh api でインラインレビューコメントを取得する。"""
    result = subprocess.run(
        [
            "gh", "api", "--paginate",
            f"repos/{owner}/{repo}/pulls/{pr_num}/comments",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Error: gh api failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return json.loads(result.stdout)


def group_into_threads(comments: list[dict]) -> list[dict]:
    """コメントをスレッドごとにグループ化する。

    in_reply_to_id が None のものがスレッドの先頭。
    それ以外は先頭コメントへの返信。
    """
    roots: dict[int, dict] = {}
    replies: dict[int, list[dict]] = {}

    for c in comments:
        reply_to = c.get("in_reply_to_id")
        if reply_to is None:
            roots[c["id"]] = c
            replies.setdefault(c["id"], [])
        else:
            replies.setdefault(reply_to, []).append(c)

    threads = []
    for cid, root in roots.items():
        threads.append({
            "root": root,
            "replies": sorted(replies.get(cid, []), key=lambda x: x["created_at"]),
        })
    return threads


def is_bot(user: dict) -> bool:
    return user.get("type", "").lower() == "bot"


def format_threads(
    threads: list[dict], owner: str, repo: str, pr_num: str
) -> str:
    lines: list[str] = []
    lines.append(f"## レビューコメント (PR #{pr_num}, {owner}/{repo})")
    lines.append(f"リポジトリ: https://github.com/{owner}/{repo}")
    lines.append("")

    actionable = []
    skipped_bot = 0

    for t in threads:
        root = t["root"]
        if is_bot(root["user"]):
            skipped_bot += 1
            continue
        actionable.append(t)

    if not actionable:
        lines.append("レビューコメントはありません。")
        if skipped_bot > 0:
            lines.append(f"(bot コメント {skipped_bot} 件をスキップ)")
        return "\n".join(lines)

    for i, t in enumerate(actionable, 1):
        root = t["root"]
        path = root.get("path", "?")
        line = root.get("line") or root.get("original_line") or "?"
        author = root["user"]["login"]
        body = root["body"].strip()
        comment_id = root["id"]

        lines.append(f"### スレッド {i} [comment_id: {comment_id}]")
        lines.append(f"- **@{author}** — `{path}:{line}`")
        lines.append(f"- 本文: {body}")

        for reply in t["replies"]:
            r_author = reply["user"]["login"]
            r_body = reply["body"].strip()
            lines.append(f"  - 返信 @{r_author}: {r_body}")

        lines.append("")

    if skipped_bot > 0:
        lines.append(f"(bot コメント {skipped_bot} 件をスキップ)")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("PR URL が指定されていません。Claude が手動でコメントを取得します。")
        sys.exit(0)

    arg = sys.argv[1].strip()
    owner, repo, pr_num = parse_pr_url(arg)

    if not owner:
        print(f"URL をパースできませんでした: {arg}")
        print("Claude が手動でコメントを取得します。")
        sys.exit(0)

    comments = fetch_comments(owner, repo, pr_num)
    threads = group_into_threads(comments)
    print(format_threads(threads, owner, repo, pr_num))


if __name__ == "__main__":
    main()
