---
name: resolve-issue
description: GitHub Issueを解決し、コミット・PR作成まで一貫して行います。Issue番号を指定して使用。
allowed-tools: Read, Grep, Glob, Bash, Task, Edit, Write, AskUserQuestion
---

# Issue解決スキル

**出力は常に日本語で行う。**

## 使用方法

```
/resolve-issue #123
/resolve-issue 123
/resolve-issue https://github.com/owner/repo/issues/123
```

## ワークフロー

### Step 1: Issue分析

```bash
gh issue view <issue番号> --json title,body,labels,assignees,comments
```

Issueの内容を分析し、以下を把握する：
- 問題の概要
- 期待される動作
- 再現手順（あれば）
- 関連するコード領域

### Step 2: 実装計画の提示

コード変更前に、以下を提示してユーザー確認を取る：
- 変更対象ファイル
- 実装アプローチ
- 考慮すべき点

### Step 3: ブランチ作成

実装計画の承認後、コード変更の前に作業用ブランチを作成する:

1. 現在のブランチがmain/developmentであることを確認（そうでなければユーザーに確認）
2. 最新のリモートを取得してブランチを作成

```bash
git fetch origin
git checkout -b <ブランチ名> origin/development
```

ブランチ名の形式: `<type>/<簡潔な説明>`（例: `fix/auth-token-expiry`, `feat/add-search-filter`）
- Issueのタイトルやラベルから適切なtype（fix, feat, refactor, chore等）と説明を決定する

### Step 4: コード実装

計画に基づいてコードを実装する：
- 既存のコードスタイルに従う
- 必要に応じてテストを追加/修正
- エラーハンドリングを適切に行う

### Step 5: 確認 → コミット

実装完了後、ユーザーに確認を求める：

```
実装が完了しました。

## 変更内容
- [変更ファイル一覧と概要]

コミットを作成しますか？
```

**確認後のコミット作成:**
```bash
git add <変更ファイル>
git commit -m "<コミットメッセージ>"
```

コミットメッセージ形式:
```
<type>: <簡潔な説明>

<詳細な説明（必要に応じて）>
```

type: fix, feat, refactor, docs, test, chore など

### Step 6: 確認 → PR作成

コミット後、ユーザーに確認を求める：

```
コミットを作成しました。

PRを作成しますか？
```

**確認後のPR作成:**

1. 現在のブランチがmain/developmentでないことを確認
2. ブランチがなければ作成してプッシュ

```bash
git push -u origin <ブランチ名>
```

3. PRテンプレートをReadツールで取得（以下の順で探索）
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.github/pull_request_template.md`
   - `PULL_REQUEST_TEMPLATE.md`

4. PR作成

```bash
gh pr create --title "<PRタイトル>" --body "<テンプレートに沿った本文>"
```

テンプレートがない場合のデフォルト本文:
```markdown
## 概要
<Issueの問題と解決内容>

## 変更内容
- <変更点1>
- <変更点2>
```

## 注意事項

- 各ステップで問題が発生した場合は、ユーザーに報告して指示を仰ぐ
- 大規模な変更の場合は、段階的に実装することを提案する
- セキュリティに関わる変更は特に慎重に行う
