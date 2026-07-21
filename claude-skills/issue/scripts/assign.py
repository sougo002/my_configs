#!/usr/bin/env python3
"""issue に assignee を追加する。

Usage:
    python3 ~/.claude/skills/issue/scripts/assign.py \
        --repo OWNER/REPO --number 123 --number 124 --assignee octocat
"""

import argparse

from _common import run_gh, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="issue に assignee を追加する")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    p.add_argument("--number", action="append", required=True, type=int, help="issue番号（複数可）")
    p.add_argument("--assignee", action="append", required=True, help="アサイン先（複数可）")
    args = p.parse_args()

    repo = validate_repo(args.repo)
    for n in args.number:
        gh_args = ["issue", "edit", str(n), "--repo", repo]
        for a in args.assignee:
            gh_args += ["--add-assignee", a]
        run_gh(gh_args)
        print(f"assigned {', '.join(args.assignee)} -> #{n}")


if __name__ == "__main__":
    main()
