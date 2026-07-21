---
name: review-pr
description: PRのURLまたはリポジトリ名:ブランチ名を受け取り、worktree上でレビューを実行します。PRレビュー時に使用。
allowed-tools: Read, Grep, Glob, Bash, Task, Skill
---

# PRレビュースキル

**出力は常に日本語で行う。**

このスキルはレビューのみを行い、コードの修正は行わない。

## 入力形式

以下のいずれかを引数として受け取る:

1. **PR URL**: `https://github.com/<owner>/<repo>/pull/<number>`
2. **リポジトリ名:ブランチ名**: `my-app:feature/add-auth` or `my-app-api:feature/add-auth`
3. **複数リポジトリ**（スペース区切り）: `my-app:feature/x my-app-api:feature/x`

### オプション

引数の末尾に `re-review` を付与すると、既存レポートの有無にかかわらず Step 0 から全ステップを再実行する。

引数の末尾に `deep` を付与すると、REVIEW-PROCESS の「深掘りモード」を有効化する（該当サブエージェントに厳格 rubric を適用）。

例: `/review-pr https://github.com/OWNER/REPO/pull/123 re-review`
例: `/review-pr my-app:feature/add-auth deep`

PR URLの場合は `gh pr view <url> --json headRefName,baseRefName,headRepository` でブランチ名・ベースブランチ・リポジトリを取得する。

## ベースブランチ

デフォルトは `development`。PR URLから取得できた場合はそちらを優先する（gitStatusの "Main branch for PRs" は使わない）。

三点ドットで分岐点からの差分のみを対象とする:

```bash
git diff <base>...HEAD
```

## ワークスペース前提

リポジトリルートの親ディレクトリを `<workspace>` として扱う。
`git rev-parse --show-toplevel` でリポジトリルートを確定し、その親を `<workspace>` とする:

```bash
repo_root=$(git -C <repo-path> rev-parse --show-toplevel)
workspace=$(dirname "$repo_root")
```

例: `/home/user/projects/my-app/backend/` で実行 → リポジトリルート `/home/user/projects/my-app/` → `<workspace>` は `/home/user/projects/`。

## ワークフロー

### 開始ステップの判定

ワークフロー開始前に、既存のレビュー結果が存在するか確認する。

1. 入力からリポジトリ名・ブランチ名を特定し、`<safe-branch>` を算出する
2. `<workspace>/pr-review/reports/<repo>--<safe-branch>.md` の存在を確認する
3. 判定:
   - **`re-review` が指定されている場合**: 既存レポートを無視し、Step 0 から全ステップを再実行する
   - **レポートが存在する場合**: レポートの内容を読み込み、既存の所見を妥当性検証の入力として使用する。Step 2〜3 はスキップし、**Step 4（妥当性検証）から開始**する。PRの目的は既存レポートの「PRの目的」セクションを再利用し、無ければ Step 1 を実行して取得する。対応するworktreeが存在すればそのまま使用し、なければ Step 0 のみ実行してworktreeを準備する
   - **レポートが存在しない場合**: Step 0 から通常どおり開始する

### Step 0: Worktree作成

各リポジトリに対して、ブランチ名の `/` を `--` に置換した名前（`<safe-branch>`）を使い、
`<workspace>/pr-review/worktrees/<repo>--<safe-branch>` にworktreeを作成する。

例: リポジトリ `my-app-api`、ブランチ `feature/add-auth`
→ `<workspace>/pr-review/worktrees/my-app-api--feature--add-auth`

```bash
cd <workspace>/<repo>
git fetch origin <branch>
safe_branch=$(echo "<branch>" | sed 's|/|--|g')
worktree_path="<workspace>/pr-review/worktrees/<repo>--$safe_branch"
if [ ! -d "$worktree_path" ]; then
  git worktree add -b "<branch>" "$worktree_path" origin/<branch>
fi
```

### Step 1: PR目的の理解（メインエージェント）

レビューに入る前に、このPRが何を解決しようとしているのかを把握する。

```bash
# PR URL入力の場合
gh pr view <url> --json title,body,closingIssuesReferences

# リポジトリ名:ブランチ名入力の場合は対応するPRを探す
gh pr list --repo <owner>/<repo> --head <branch> --json number,title,body,closingIssuesReferences
```

- `closingIssuesReferences` にissueがあれば `gh issue view <number> --repo <owner>/<repo> --json title,body` で内容を取得する
- PR本文中にissue参照（`#123`、issue URL等）があればそれも取得する
- PRが見つからない場合は、コミットメッセージ（`git log <base>..HEAD --oneline`）とブランチ名から意図を推測する

把握した内容を「**変更の目的**」としてまとめる:

```
- 解決したい課題: [issueやPR本文から]
- 変更のアプローチ: [PR本文・コミットメッセージから]
- スコープ外: [PR本文に明記があれば。なければ省略]
```

このサマリーは Step 3-4 のレビューに入力として渡し、最終レポートの「PRの目的」セクションにも記載する。

複数リポジトリの場合は、リポジトリごとにPRを探して目的をまとめる（同一機能の分割PRであれば統合してよい）。

### Step 2: 差分取得（メインエージェント）

worktree上で実行する。

```bash
cd <workspace>/pr-review/worktrees/<repo>--<safe-branch>   # worktreeのパス
git diff --name-status <base>...HEAD   # 変更ファイル一覧（A/M/D）
git diff <base>...HEAD                 # diff（ファイル単位で構造化されている）
```

複数リポジトリの場合は、各worktreeで差分を取得し、リポジトリ名付きで結合する。

### Step 3-4: レビュー実行と妥当性検証

[../review/REVIEW-PROCESS.md](../review/REVIEW-PROCESS.md) の手順に従い、並列レビュー（5サブエージェント）と妥当性検証を実行する。

- **作業ディレクトリ**: worktreeのパス
- **変更の目的**: Step 1 でまとめたサマリーを渡す
- **深掘りモード**: `deep` オプションが指定されている場合は有効化する

### Step 5: 統合（メインエージェント）

検証済みの指摘のみを統合し、出力形式に従ってレビュー結果を生成する。

### Step 6: 処理フロー全体像の出力

レビュー結果の提示後、今回の変更が組み込まれる処理フローの全体像を概略で出力する。
変更箇所がその処理フローのどこに位置するかが分かるようにする。

## 出力形式

レビュー結果は `<workspace>/pr-review/reports/<repo>--<safe-branch>.md` に保存:

```markdown
## PRの目的
- 解決したい課題: [Step 1 のサマリー]
- 変更のアプローチ: [Step 1 のサマリー]

## サマリー
- 変更ファイル数: X
- 行数: +XXX / -XXX
- スコープ: [frontend/backend/database/config]

## 評価
- グレード: [S/A+/A/B+/B/C+/C/D]
- マージ推奨: [Ready/軽微な修正が必要/修正が必要/要再作業]
- 目的適合性: [目的を達成している/過不足あり（詳細は所見を参照）]

## 所見

### 良い実装
- [具体例]

### Critical Issues
- [セキュリティリスク、バグ]

### Warnings
- [設計上の問題、パフォーマンス]

### Suggestions
- [将来的な改善提案]

## 推奨アクション
1. 即時対応: [重大な修正]
2. 短期: [重要な改善]
3. 長期: [技術的負債]
```

## 注意事項

- 変更のコンテキストと意図を考慮する
- 建設的で実行可能なフィードバックを提供する
- 所見は重大度順に優先度付けする
- worktreeの作成に失敗した場合はユーザーに報告する
- **レビュー結果（Step 5-6）を出力したらそこで終了する。「PRを修正しますか？」等の修正・次アクションの提案や、締めの問いかけは行わない。**
