#!/usr/bin/env python3
"""GitHub PR情報を取得するスクリプト"""

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


def query_review_requested(username: str, limit: int, repo: str | None) -> list:
	"""レビューリクエストされているPRを取得"""
	cmd = [
		"gh", "search", "prs",
		f"--review-requested={username}",
		"--state=open",
		"--draft=false",
		f"--limit={limit}",
		"--json", "repository,number,title,url,author,createdAt"
	]
	if repo:
		cmd.extend(["--repo", repo])

	result = subprocess.run(cmd, capture_output=True, text=True)
	if result.returncode != 0:
		print(f"Error: {result.stderr}", file=sys.stderr)
		return []

	return json.loads(result.stdout) if result.stdout else []


def query_author_prs(username: str, limit: int, repo: str | None) -> list:
	"""自分が作成したPRを取得"""
	cmd = [
		"gh", "search", "prs",
		f"--author={username}",
		"--state=open",
		f"--limit={limit}",
		"--json", "repository,number,title,url,state,createdAt,isDraft"
	]
	if repo:
		cmd.extend(["--repo", repo])

	result = subprocess.run(cmd, capture_output=True, text=True)
	if result.returncode != 0:
		print(f"Error: {result.stderr}", file=sys.stderr)
		return []

	return json.loads(result.stdout) if result.stdout else []


def format_pr(pr: dict, show_author: bool = False) -> str:
	"""PRを表示用にフォーマット"""
	repo_name = pr.get("repository", {}).get("nameWithOwner", "unknown")
	number = pr.get("number", "?")
	title = pr.get("title", "No title")
	url = pr.get("url", "")

	line = f"- [{repo_name}#{number}]({url}) {title}"

	if show_author:
		author = pr.get("author", {}).get("login", "unknown")
		line += f" (@{author})"

	if pr.get("isDraft"):
		line += " [Draft]"

	return line


def main():
	parser = argparse.ArgumentParser(description="GitHub PR情報を取得")
	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument("--review-requested", action="store_true", help="レビュー待ちPR")
	group.add_argument("--author", action="store_true", help="自分が作成したPR")
	parser.add_argument("--limit", type=int, default=20, help="取得件数")
	parser.add_argument("--repo", type=str, help="リポジトリ (OWNER/REPO)")
	parser.add_argument("--json", action="store_true", dest="output_json", help="JSON形式で出力")

	args = parser.parse_args()

	username = get_github_username()

	if args.review_requested:
		prs = query_review_requested(username, args.limit, args.repo)
		title = "レビュー待ちPR"
		show_author = True
	else:
		prs = query_author_prs(username, args.limit, args.repo)
		title = "自分が作成したPR"
		show_author = False

	if args.output_json:
		print(json.dumps(prs, ensure_ascii=False, indent=2))
	else:
		print(f"【{title}】({len(prs)}件)")
		if not prs:
			print("なし")
		else:
			for pr in prs:
				print(format_pr(pr, show_author))


if __name__ == "__main__":
	main()
