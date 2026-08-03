#!/usr/bin/env python3
"""issue を親issueの sub-issue として紐付ける（GraphQL addSubIssue）。

`gh issue edit` に sub-issue 用フラグが無いため GraphQL mutation を使う。

Usage:
    python3 ~/.claude/skills/issue/scripts/link_subissue.py \
        --repo OWNER/REPO --parent 100 --child 101 --child 102
"""

import argparse

from _common import add_sub_issue, graphql, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="issue を sub-issue として親に紐付ける")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    p.add_argument("--parent", required=True, type=int)
    p.add_argument("--child", action="append", required=True, type=int, help="子issue番号（複数可）")
    args = p.parse_args()

    owner, name = validate_repo(args.repo).split("/")

    # parent と全 child の nodeID をまとめて取得
    child_fields = "\n".join(
        f"c{i}: issue(number: {n}) {{ id number title }}" for i, n in enumerate(args.child)
    )
    query = f"""
    {{
      repository(owner: "{owner}", name: "{name}") {{
        parent: issue(number: {args.parent}) {{ id }}
        {child_fields}
      }}
    }}"""
    repo = graphql(query)["data"]["repository"]
    parent_id = repo["parent"]["id"]

    for i, n in enumerate(args.child):
        child = repo[f"c{i}"]
        add_sub_issue(parent_id, child["id"])
        print(f"linked #{child['number']} ({child['title']}) -> parent #{args.parent}")


if __name__ == "__main__":
    main()
