---
name: review-pr
description: PRのURLまたはリポジトリ名:ブランチ名を受け取り、worktree上でレビューを実行します。PRレビュー時に使用。
allowed-tools: Read, Grep, Glob, Bash, Task
---

# PRレビュースキル

**出力は常に日本語で行う。**

## 入力形式

以下のいずれかを引数として受け取る:

1. **PR URL**: `https://github.com/<owner>/<repo>/pull/<number>`
2. **リポジトリ名:ブランチ名**: `mntsq:feature/add-auth` or `mntsq-algo:feature/add-auth`
3. **複数リポジトリ**（スペース区切り）: `mntsq:feature/x mntsq-algo:feature/x`

### オプション

引数の末尾に `re-review` を付与すると、既存レポートの有無にかかわらず Step 0 から全ステップを再実行する。

例: `/review-pr https://github.com/MNTSQ/mntsq/pull/123 re-review`

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
   - **レポートが存在する場合**: レポートの内容を読み込み、既存の所見を妥当性検証の入力として使用する。Step 0〜2 はスキップし、**Step 3 から開始**する。対応するworktreeが存在すればそのまま使用し、なければ Step 0 のみ実行してworktreeを準備する
   - **レポートが存在しない場合**: Step 0 から通常どおり開始する

### Step 0: Worktree作成

各リポジトリに対して、ブランチ名の `/` を `--` に置換した名前（`<safe-branch>`）を使い、
`<workspace>/pr-review/worktrees/<repo>--<safe-branch>` にworktreeを作成する。

例: リポジトリ `mntsq-algo`、ブランチ `feature/add-auth`
→ `<workspace>/pr-review/worktrees/mntsq-algo--feature--add-auth`

```bash
cd <workspace>/<repo>
git fetch origin <branch>
safe_branch=$(echo "<branch>" | sed 's|/|--|g')
worktree_path="<workspace>/pr-review/worktrees/<repo>--$safe_branch"
git worktree add "$worktree_path" origin/<branch>
```

### Step 1: 差分取得（メインエージェント）

worktree上で実行する。

```bash
cd <workspace>/pr-review/worktrees/<repo>--<safe-branch>   # worktreeのパス
git diff --name-status <base>...HEAD   # 変更ファイル一覧（A/M/D）
git diff <base>...HEAD                 # diff（ファイル単位で構造化されている）
```

複数リポジトリの場合は、各worktreeで差分を取得し、リポジトリ名付きで結合する。

### Step 2-3: レビュー実行と妥当性検証

[../review/REVIEW-PROCESS.md](../review/REVIEW-PROCESS.md) の手順に従い、並列レビュー（4サブエージェント）と妥当性検証を実行する。

- **作業ディレクトリ**: worktreeのパス
- **ガイドファイル**: `../review/` 配下（ARCHITECTURE.md, SECURITY.md, CHECKLIST.md）

### Step 4: 統合（メインエージェント）

検証済みの指摘のみを統合し、出力形式に従ってレビュー結果を生成する。

### Step 5: Worktree削除

レビュー完了後、worktreeを削除するかユーザーに確認する。
ユーザーがそのまま対応する可能性があるため、**確認なしに削除してはならない**。

worktreeのパスを提示し、削除するか残すかを尋ねる:

```
レビューが完了しました。worktreeを削除しますか？
パス: <workspace>/pr-review/worktrees/<repo>--<safe-branch>
（そのまま対応する場合は残すことができます）
```

ユーザーが削除を承認した場合のみ実行:

```bash
cd <workspace>/<repo>
git worktree remove "<workspace>/pr-review/worktrees/<repo>--$safe_branch"
```

複数リポジトリの場合は全てのworktreeについて確認する。

## 出力形式

レビュー結果は `<workspace>/pr-review/reports/<repo>--<safe-branch>.md` に保存:

```markdown
## サマリー
- 変更ファイル数: X
- 行数: +XXX / -XXX
- スコープ: [frontend/backend/database/config]

## 評価
- グレード: [S/A+/A/B+/B/C+/C/D]
- マージ推奨: [Ready/軽微な修正が必要/修正が必要/要再作業]

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
- worktreeの作成・削除に失敗した場合はユーザーに報告する
