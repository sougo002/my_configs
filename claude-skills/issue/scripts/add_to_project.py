#!/usr/bin/env python3
"""issue を GitHub Project に追加する（冪等）。

Project 操作には `project` スコープが必要（未付与なら `gh auth refresh -s project`）。

Usage:
    python3 ~/.claude/skills/issue/scripts/add_to_project.py \
        --owner OWNER --project-number PROJECT_NUMBER \
        --url https://github.com/OWNER/REPO/issues/1
"""

import argparse

from _common import add_to_project


def main() -> None:
    p = argparse.ArgumentParser(description="issue を GitHub Project に追加する")
    p.add_argument("--owner", required=True, help="Project の owner")
    p.add_argument("--project-number", required=True, help="Project 番号")
    p.add_argument("--url", action="append", required=True, help="issue URL（複数可）")
    args = p.parse_args()

    add_to_project(args.owner, args.project_number, args.url)
    for u in args.url:
        print(f"added to project {args.owner}/{args.project_number}: {u}")


if __name__ == "__main__":
    main()
