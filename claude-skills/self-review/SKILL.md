---
name: self-review
description: 現在のブランチの変更をセルフレビューし、発見した問題を自動修正・コミットします。コミット前のセルフチェックに使用。
allowed-tools: Read, Grep, Glob, Bash(make lint*), Bash(make test*), Bash(gh pr view *), Bash(git status*), Bash(git fetch *), Bash(git diff *), Bash(git log *), Bash(git rev-parse *), Bash(git branch*), Task, AskUserQuestion
---

# セルフレビュースキル

**出力は常に日本語で行う。**

## 入力形式

引数なしで実行する。現在のブランチの変更を対象とする。

### オプション

- `--base <branch>`: ベースブランチを指定（デフォルト: `development`）
- `--no-fix`: レビューのみ行い、修正は行わない（所見の表示で終了）

## ワークフロー

### Step 1: ブランチ状態の確認

```bash
current_branch=$(git rev-parse --abbrev-ref HEAD)
```

- `main` または `development` ブランチの場合はエラーで中止する
- ベースブランチを確定する（引数指定 > デフォルト `development`）

```bash
git fetch origin <base>

# コミット済み差分
git diff --name-status <base>...HEAD
git diff <base>...HEAD

# ローカルの未コミット変更（ステージング済み + 未ステージング）
git diff HEAD
```

コミット済み差分もローカル変更もない場合はエラーで中止する。

### Step 2: スコープガード

変更対象ファイル一覧を取得し、以降のすべての修正をこの範囲内に制限する。

```bash
# コミット済み + ローカル変更の両方を含むファイル一覧
git diff --name-only <base>...HEAD
git diff --name-only HEAD
```

### Step 3: レビュー実行

[../review/REVIEW-PROCESS.md](../review/REVIEW-PROCESS.md) の手順に従い、並列レビュー（4サブエージェント）と妥当性検証を実行する。

- **作業ディレクトリ**: 現在のリポジトリルート
- **ガイドファイル**: `../review/` 配下（ARCHITECTURE.md, SECURITY.md, CHECKLIST.md）

### Step 4: 所見の提示と選択

検証済みの所見を優先度順に一覧表示する:

```
## セルフレビュー結果

### 修正可能な所見
1. [Critical] ファイル:行 - 説明
2. [High] ファイル:行 - 説明
3. [Medium] ファイル:行 - 説明

### 情報のみ（修正不要）
- [Low] ...

### 良い実装
- ...

どの所見を修正しますか？（番号をカンマ区切り、"all" で全て、"none" でスキップ）
```

`--no-fix` の場合はここで終了する。

### Step 5: 所見ごとの修正

選択された各所見について、優先度の高い順に以下を実行する:

1. **確認**: 該当コードを Read で再確認し、所見が依然として有効であることを検証する。前の修正で解消済みの場合はスキップし、理由を報告する
2. **修正**: Edit で最小限のコード修正を行う
3. **リント**: `make lint` を実行する。失敗したらスコープ内で修正してリトライする
4. **コミット**: 1所見 = 1コミット

```bash
git add <修正ファイル>
git commit -m "<type>: <修正内容の説明>"
```

#### コミットメッセージのルール

- 何を修正したかを具体的に記述する（例: `fix: add null check for user input in auth handler`）
- `fix review comment`、`address self-review finding`、`レビュー対応` のような曖昧な表現は禁止
- type: `fix`, `refactor`, `style`, `test`, `docs` など

### Step 6: テスト実行

全修正完了後:

```bash
make test
```

テストが失敗した場合はユーザーに報告し、修正するか確認する。

### Step 7: サマリー

```
## セルフレビュー完了

### 修正した所見
- [commit hash] <説明>
- [commit hash] <説明>

### スキップした所見
- <所見> — 理由: <なぜスキップしたか>

### テスト結果
- 結果: PASS / FAIL
```

## 注意事項

- スコープガード: PR変更範囲外のファイルは修正しない
- 各修正前に実際のコードを確認してから修正する（指摘を鵜呑みにしない）
- リント失敗は修正してからコミットする
- 大規模な構造変更は提案のみにとどめ、ユーザーの判断を仰ぐ
