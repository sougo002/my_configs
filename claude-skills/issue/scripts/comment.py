#!/usr/bin/env python3
"""GitHub issue にコメントを投稿 / 既存コメントを更新する。

本文は --body-file または stdin で渡す。

- 新規投稿: --number を指定。`{"id":.., "url":..}` の JSON を返す。
- 更新   : --comment-id を指定。本文を差し替える。
- 追記   : --comment-id に加えて --append。既存本文を取得し、末尾に本文を足して更新する。

Usage:
    python3 ~/.claude/skills/issue/scripts/comment.py --repo OWNER/REPO --number 123 --body-file body.md
    python3 ~/.claude/skills/issue/scripts/comment.py --repo OWNER/REPO --comment-id 456 --append --body-file add.md
"""

import argparse
import json

from _common import read_body, run_gh, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="GitHub issue にコメントを投稿 / 更新する")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--number", type=int, help="新規コメントを投稿する issue 番号")
    g.add_argument("--comment-id", type=int, help="更新する既存コメントの ID")
    p.add_argument("--append", action="store_true", help="--comment-id 指定時、既存本文の末尾に追記する")
    p.add_argument("--body-file", help="本文ファイル。未指定なら stdin を読む")
    args = p.parse_args()

    repo = validate_repo(args.repo)
    body = read_body(args)
    if body is None:
        raise SystemExit("本文(--body-file/stdin)を指定してください")

    if args.number is not None:
        # 新規投稿
        out = run_gh(
            ["api", f"repos/{repo}/issues/{args.number}/comments", "-X", "POST", "-f", f"body={body}"]
        )
        data = json.loads(out)
        print(json.dumps({"id": data["id"], "url": data["html_url"]}, ensure_ascii=False))
        return

    # 既存コメントの更新
    if args.append:
        current = run_gh(["api", f"repos/{repo}/issues/comments/{args.comment_id}", "--jq", ".body"])
        body = current.rstrip("\n") + "\n\n" + body
    out = run_gh(
        ["api", f"repos/{repo}/issues/comments/{args.comment_id}", "-X", "PATCH", "-f", f"body={body}"]
    )
    data = json.loads(out)
    print(json.dumps({"id": data["id"], "url": data["html_url"]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
