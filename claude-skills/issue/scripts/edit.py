#!/usr/bin/env python3
"""GitHub issue の title / body を書き換える。

本文は --body-file または stdin で渡す。

Usage:
    python3 ~/.claude/skills/issue/scripts/edit.py --repo OWNER/REPO --number 123 --title "新タイトル"
    cat new_body.md | python3 ~/.claude/skills/issue/scripts/edit.py --repo OWNER/REPO --number 123
"""

import argparse

from _common import read_body, run_gh, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="GitHub issue の title / body を書き換える")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    p.add_argument("--number", required=True, type=int)
    p.add_argument("--title")
    p.add_argument("--body-file", help="本文ファイル。未指定なら stdin を読む")
    args = p.parse_args()

    repo = validate_repo(args.repo)
    body = read_body(args)
    if not args.title and body is None:
        raise SystemExit("--title か本文(--body-file/stdin)のいずれかを指定してください")

    gh_args = ["issue", "edit", str(args.number), "--repo", repo]
    if args.title:
        gh_args += ["--title", args.title]
    if body is not None:
        gh_args += ["--body", body]

    print(run_gh(gh_args).strip())


if __name__ == "__main__":
    main()
