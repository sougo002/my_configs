#!/usr/bin/env python3
"""GitHub Issue情報を取得するスクリプト"""

import subprocess
import json
import argparse
import sys


def get_github_username():
	"""gh CLIからGitHubユーザー名を取得"""
	result = subprocess.run(
		["gh", "api", "user", "--jq", ".login"],
		capture_output=True,
		text=True
	)
	if result.returncode != 0:
		print("Error: gh CLIでユーザー情報を取得できませんでした", file=sys.stderr)
		sys.exit(1)
	return result.stdout.strip()


def query_assigned_issues(username: str, limit: int, repo: str | None) -> list:
	"""アサインされているIssueを取得"""
	cmd = [
		"gh", "search", "issues",
		f"--assignee={username}",
		"--state=open",
		f"--limit={limit}",
		"--json", "repository,number,title,url,labels,createdAt"
	]
	if repo:
		cmd.extend(["--repo", repo])

	result = subprocess.run(cmd, capture_output=True, text=True)
	if result.returncode != 0:
		print(f"Error: {result.stderr}", file=sys.stderr)
		return []

	return json.loads(result.stdout) if result.stdout else []


def format_issue(issue: dict) -> str:
	"""Issueを表示用にフォーマット"""
	repo_name = issue.get("repository", {}).get("nameWithOwner", "unknown")
	number = issue.get("number", "?")
	title = issue.get("title", "No title")
	url = issue.get("url", "")

	line = f"- [{repo_name}#{number}]({url}) {title}"

	labels = issue.get("labels", [])
	if labels:
		label_names = [l.get("name", "") for l in labels if l.get("name")]
		if label_names:
			line += f" [{', '.join(label_names)}]"

	return line


def main():
	parser = argparse.ArgumentParser(description="GitHub Issue情報を取得")
	parser.add_argument("--assigned", action="store_true", required=True, help="アサインされたIssue")
	parser.add_argument("--limit", type=int, default=20, help="取得件数")
	parser.add_argument("--repo", type=str, help="リポジトリ (OWNER/REPO)")
	parser.add_argument("--json", action="store_true", dest="output_json", help="JSON形式で出力")

	args = parser.parse_args()

	username = get_github_username()
	issues = query_assigned_issues(username, args.limit, args.repo)

	if args.output_json:
		print(json.dumps(issues, ensure_ascii=False, indent=2))
	else:
		print(f"【アサインされたIssue】({len(issues)}件)")
		if not issues:
			print("なし")
		else:
			for issue in issues:
				print(format_issue(issue))


if __name__ == "__main__":
	main()
