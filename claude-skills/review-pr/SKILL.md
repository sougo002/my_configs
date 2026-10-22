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

引数の末尾に `deep` を付与すると、REVIEW-PROCESS の「深掘りモード」を有効化する。

引数の末尾に `ux` を付与すると、Step 7 の UX ペルソナ検証を実行する。

例: `/review-pr https://github.com/OWNER/REPO/pull/123 re-review`
例: `/review-pr my-app:feature/add-auth deep`
例: `/review-pr my-app:feature/add-auth ux`

複数のオプションは同時に指定できる。適用順は「Step 0 → ... → Step 7（ux）→ Step 8」とする。

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

## レポートの出力先

レビュー結果は `<workspace>/pr-review/reports/<repo>--<safe-branch>/` ディレクトリに、番号付きのファイルとして保存する:

```
00-overview.md              PRの目的・このPRで変わったこと（追加・削除・変更）
01-file-classification.md   変更ファイルの分類（ファイルの重複可、deepのみ）
02-review-results.md        観点別の所見（妥当性検証前の一次結果）
03-validation.md            妥当性検証の判定（採用・修正・却下と理由）
04-runtime-check.md         実行確認の結果と未実施項目（Step 6）
05-ux-persona.md            UX ペルソナ検証
06-summary.md               最終サマリー・評価・所見
```

- レビュー結果を 1 ファイルにまとめず、作業過程をファイルとして残す
- 専門観点（セキュリティ詳細、API 契約の突合など）を追加で走らせた場合は、02 の後に番号を振って追加する（例: `02-1-security.md`、`02-2-api-contract.md`）。追加するかどうかは、メインエージェントが Step 3-4 の結果を見て必要と判断した場合のみ行う。
- 複数リポジトリの場合も `06-summary.md` は 1 つだけ作成し、先頭に指定したリポジトリのレポートディレクトリに置く。リポジトリ別の節（`## <repo>`）を設け、その中に変更規模・評価・所見を書く。

## ワークフロー

### 開始ステップの判定

ワークフロー開始前に、既存のレビュー結果が存在するか確認する。

1. 入力からリポジトリ名・ブランチ名を特定し、`<safe-branch>` を算出する
2. `<workspace>/pr-review/reports/<repo>--<safe-branch>/` ディレクトリの存在を確認する
3. 判定:
   - **`re-review` が指定されている場合**: 既存ディレクトリを無視し、Step 0 から全ステップを再実行する。既存ファイルは上書きする
   - **ディレクトリが存在する場合**: Step 2〜4 はスキップし、**Step 5（統合）から開始**する。既存の `02-review-results.md` と `03-validation.md` を Step 5 の入力として読み込む。
     - PRの目的と変更内容は既存の `00-overview.md` を再利用し、無ければ Step 1 を実行して取得する。
     - 対応するworktreeが存在すればそのまま使用し、なければ Step 0 のみ実行してworktreeを準備する
   - **ディレクトリが存在しない場合**: Step 0 から通常どおり開始する

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
if git worktree list --porcelain | grep -qxF "worktree $worktree_path"; then
  : # 既存 worktree をそのまま使う
elif git show-ref --verify --quiet "refs/heads/<branch>"; then
  git worktree add "$worktree_path" "<branch>"   # 同名のローカルブランチが既にあればそれを使う
else
  git worktree add -b "<branch>" "$worktree_path" origin/<branch>
fi
```

既存 worktree の判定は `git worktree list` で行う。同名のローカルブランチが既にある場合は、`-b` で新規作成せず既存ブランチを使って worktree を作成する。

### Step 1: PR目的の理解（メインエージェント）

レビューに入る前に、このPRが何を解決しようとしているのか（目的）と、このPRで何が変わったのか（変更内容）を把握する。
worktree上で実行する。

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

「**このPRで変わったこと**」は、`git diff --name-status <base>...HEAD` の出力を元に、ファイル名の羅列ではなく機能単位で追加・削除・変更をまとめる。

これらは最初に `00-overview.md` に保存する。構成は次の 2 節とする:

```
## PRの目的
- 解決したい課題: [Step 1 のサマリー]
- 変更のアプローチ: [Step 1 のサマリー]
- スコープ外: [PR本文に明記があれば。なければ省略]

## このPRで変わったこと
- 追加: [機能単位]
- 削除: [機能単位]
- 変更: [機能単位]
```

このサマリーは Step 3-4 のレビューに入力として渡し、最終レポートの「PRの目的」セクションにも記載する。

複数リポジトリの場合は、リポジトリごとにPRを探して目的をまとめる（同一機能の分割PRであれば統合してよい）。

### Step 2: 差分取得と分類（メインエージェント）

worktree上で実行する。

```bash
cd <workspace>/pr-review/worktrees/<repo>--<safe-branch>   # worktreeのパス
git diff --name-status <base>...HEAD   # 変更ファイル一覧（A/M/D）
git diff <base>...HEAD                 # diff（ファイル単位で構造化されている）
```

複数リポジトリの場合は、各worktreeで差分を取得し、リポジトリ名付きで結合する。

取得した変更ファイルを観点（画面・API・権限・DB・テスト・設定など）で分類し、`01-file-classification.md` に書く。1 ファイルが複数の分類に入ってよい。`deep` オプションが指定された場合のみ作成する。
あわせて、フロントエンド差分の有無を REVIEW-PROCESS の「フロントエンド差分の検出」の拡張子条件で判定する。
### Step 3-4: レビュー実行と妥当性検証

[../review/REVIEW-PROCESS.md](../review/REVIEW-PROCESS.md) の手順に従い、並列レビューと妥当性検証を実行する。

- **作業ディレクトリ**: worktreeのパス
- **変更の目的**: Step 1 でまとめたサマリーを渡す
- **深掘りモード**: `deep` オプションが指定されている場合は有効化する

一次結果は `02-review-results.md` に、妥当性検証の判定は `03-validation.md` に書く。
妥当性検証はメインエージェントが行う。サブエージェントの指摘をそのまま採用しない。

### Step 5: 統合（メインエージェント）

検証済みの指摘のみを統合し、サマリーを生成する。
「却下」（「いらない」と判断したものを含む）の指摘も、理由とともに `03-validation.md` に残し、`06-summary.md` には含めない。

### Step 6: 実行確認の切り出し（メインエージェント・サブエージェント）

妥当性検証で「実行確認へ回す」と判定された項目（実データの確認、API の実レスポンス確認、ローカル環境での起動確認、DB の突合など）は、メインで抱えず項目ごとにサブエージェントに切り出す。

- 各サブエージェントには確認内容・確認手順・判定基準を渡す。
- 結果は `04-runtime-check.md` に「実施結果」と「未実施（理由）」を分けて書く。
  - 理由無く未実施にしない。検証できる範囲は検証する
- 確定した採用・却下の判定はメインエージェントが行い、`03-validation.md` に追記したうえで、`06-summary.md` の所見に反映する。実行確認の最終判定もメインエージェントが行う。

### Step 7: UX ペルソナ検証

- ブラウザ操作ができるサブエージェント種別を使い、ペルソナごとに 1 つずつ起動する。
- ペルソナには役割・業務・操作の目的・見て欲しい箇所だけを与え、「不満点」「機能要望」「良かった点」を画面上の動作で報告させる。
- 成果物があれば `ux-artifacts/<persona>/` に保存する。
- 報告の採否はメインエージェントが妥当性検証と同じ基準で判定してから `05-ux-persona.md` に統合する。このPRと関係のない不満は含めない。

### Step 8: 処理フロー全体像の出力

レビュー結果の提示後、今回の変更が組み込まれる処理フローの全体像を概略で出力する。出力先は `06-summary.md` の末尾に「処理フロー」節として追記する。
変更箇所がその処理フローのどこに位置するかが分かるようにする。

## 出力形式（06-summary.md）

最終サマリーは `06-summary.md` に保存する。書式は以下:

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
- 目的適合性: [目的を達成している/過不足あり]

## 所見

### Critical Issues
- [セキュリティリスク、バグ]

### Warnings
- [設計上の問題、パフォーマンス]

### Suggestions
- [将来的な改善提案]
```

## 注意事項

- 変更のコンテキストと意図を考慮する
- 建設的で実行可能なフィードバックを提供する
- 所見は重大度順に優先度付けする
- worktreeの作成に失敗した場合はユーザーに報告する
- Step 5〜8 の結果を出力したらそこで終了する。「PRを修正しますか？」等の修正・次アクションの提案や、締めの問いかけは行わない。
