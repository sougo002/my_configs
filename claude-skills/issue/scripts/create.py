#!/usr/bin/env python3
"""GitHub issue を作成する。

本文は --body-file または stdin で渡す。作成結果を {"number":.., "url":..} の JSON で stdout に出す。

Usage:
    python3 ~/.claude/skills/issue/scripts/create.py \
        --repo OWNER/REPO --title "タイトル" --body-file body.md

    echo "本文" | python3 ~/.claude/skills/issue/scripts/create.py \
        --repo OWNER/REPO --title "T" --label bug --assignee octocat

    # sub-issue にする（本文先頭に "Parent: #100" を付加）
    python3 ~/.claude/skills/issue/scripts/create.py \
        --repo OWNER/REPO --title "T" --body-file b.md --parent 100

    # 作成後に Project へ追加
    python3 ~/.claude/skills/issue/scripts/create.py \
        --repo OWNER/REPO --title "T" --body-file b.md \
        --add-to-project --project-owner OWNER --project-number PROJECT_NUMBER
"""

import argparse
import json

from _common import add_to_project, read_body, run_gh, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="GitHub issue を作成する")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    p.add_argument("--title", required=True)
    p.add_argument("--body-file", help="本文ファイル。未指定なら stdin を読む")
    p.add_argument("--label", action="append", default=[], help="ラベル（複数可）")
    p.add_argument("--assignee", action="append", default=[], help="アサイン先（複数可）")
    p.add_argument("--parent", type=int, help="親issue番号。本文先頭に 'Parent: #N' を付加")
    p.add_argument("--add-to-project", action="store_true", help="作成後に Project へ追加")
    p.add_argument("--project-owner", help="--add-to-project 時の owner")
    p.add_argument("--project-number", help="--add-to-project 時の project 番号")
    args = p.parse_args()

    repo = validate_repo(args.repo)
    body = read_body(args) or ""
    if args.parent:
        body = f"Parent: #{args.parent}\n\n{body}"

    gh_args = ["issue", "create", "--repo", repo, "--title", args.title, "--body", body]
    for label in args.label:
        gh_args += ["--label", label]
    for assignee in args.assignee:
        gh_args += ["--assignee", assignee]

    # gh issue create は作成した issue の URL を出力する
    url = run_gh(gh_args).strip().splitlines()[-1].strip()
    number = int(url.rstrip("/").split("/")[-1])

    if args.add_to_project:
        if not (args.project_owner and args.project_number):
            raise SystemExit("--add-to-project には --project-owner と --project-number が必要です")
        add_to_project(args.project_owner, args.project_number, [url])

    print(json.dumps({"number": number, "url": url}, ensure_ascii=False))


if __name__ == "__main__":
    main()
