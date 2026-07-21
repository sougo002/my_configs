#!/usr/bin/env python3
"""親issueの sub-issue 一覧を JSON で表示する。

Usage:
    python3 ~/.claude/skills/issue/scripts/list_subissues.py --repo OWNER/REPO --parent 100
"""

import argparse
import json

from _common import graphql, validate_repo


def main() -> None:
    p = argparse.ArgumentParser(description="親issueの sub-issue 一覧を表示する")
    p.add_argument("--repo", required=True, help="OWNER/REPO")
    p.add_argument("--parent", required=True, type=int)
    args = p.parse_args()

    owner, name = validate_repo(args.repo).split("/")
    query = f"""
    {{
      repository(owner: "{owner}", name: "{name}") {{
        issue(number: {args.parent}) {{
          subIssues(first: 50) {{ nodes {{ number title state }} }}
        }}
      }}
    }}"""
    nodes = graphql(query)["data"]["repository"]["issue"]["subIssues"]["nodes"]
    print(json.dumps(nodes, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
