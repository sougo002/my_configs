---
name: github-query
description: Query GitHub information using gh CLI. Use for PRs awaiting review, my PRs, assigned issues, and repository information.
allowed-tools: Bash(gh:*), Bash(python:*)
---

# GitHub情報取得

`gh` CLIを使ってGitHub情報を取得するスキル。

## レビュー待ちPR一覧

```bash
python .claude/skills/github-query/scripts/query_prs.py --review-requested
```

## 自分が作成したPR一覧

```bash
python .claude/skills/github-query/scripts/query_prs.py --author
```

## アサインされたIssue一覧

```bash
python .claude/skills/github-query/scripts/query_issues.py --assigned
```

## オプション

| オプション | 説明 |
|-----------|------|
| `--limit N` | 取得件数（デフォルト: 20） |
| `--repo OWNER/REPO` | 特定リポジトリに絞る |
| `--json` | JSON形式で出力 |
