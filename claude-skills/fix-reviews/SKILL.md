---
name: fix-reviews
description: PRのレビューコメントを取得し、指摘事項を修正・コミットします。レビュー対応に使用。
allowed-tools: Read, Grep, Glob, Bash(make lint*), Bash(make test*), Bash(gh pr view *), Bash(git status*), Bash(git fetch *), Bash(git diff *), Bash(git log *), Bash(git rev-parse *), Bash(git branch*), AskUserQuestion
---

# レビュー指摘修正スキル

**出力は常に日本語で行う。**

## 入力形式

**PR URL** を引数として受け取る: `/fix-reviews https://github.com/MNTSQ/mntsq-ai-widget/pull/123`

PR URL 以外（PR番号、ブランチ名等）を指定した場合は、手動でコメントを取得する。

## レビューコメント（自動取得）

!`python3 ${CLAUDE_SKILL_DIR}/scripts/fetch_comments.py $ARGUMENTS`

## ワークフロー

### Step 1: コメントの確認

上記で自動取得されたレビューコメントを確認する。
自動取得できなかった場合（URL 以外の入力）は、以下で手動取得する:

```bash
gh pr view <pr_num> --comments
```

### Step 2: コメントの分類

取得したコメントを以下に分類する:

| 分類 | 基準 | アクション |
|------|------|-----------|
| コード修正依頼 | 具体的なコード変更を求めている | 修正対象 |
| 質問 | 理由や意図を尋ねている | スキップ（ユーザーが回答） |
| 承認・賛同 | LGTM、良い実装など | スキップ |
| 議論 | 設計方針の議論 | スキップ（ユーザー判断） |
| 対応済み | 後続コミットで修正済み | スキップ |

分類のヒント:
- "should", "please", "change", "fix", "add", "remove", "〜してください", "〜した方がいい" → 修正依頼の可能性が高い
- "why", "what", "?", "なぜ", "どうして" → 質問の可能性が高い
- "LGTM", "looks good", "nice", "👍" → 承認

### Step 3: 修正対象の提示と選択

```
## レビューコメント一覧

### 修正対象（コード変更依頼）
1. [comment_id: 12345] @reviewer — path/to/file.py:42
   「null チェックを追加してください」

2. [comment_id: 12346] @reviewer — path/to/handler.py:15
   「エラーハンドリングが不足しています」

### スキップ（質問・議論・承認）
- @reviewer: 「この実装にした理由は？」 → 質問
- @reviewer: 「LGTM」 → 承認

どのコメントを修正しますか？（番号をカンマ区切り、"all" で全て）
```

### Step 4: スコープガード

ベースブランチを特定し、PR変更範囲のファイルリストを取得する:

```bash
base=$(gh pr view $pr_num --json baseRefName --jq '.baseRefName')
git fetch origin "$base"
git diff --name-only "$base"...HEAD
```

修正はPR変更範囲内のファイルに限定する。
コメントが変更範囲外のファイルに言及している場合はユーザーに確認する。

### Step 5: コメントごとの修正

選択された各コメントについて、以下を順番に実行する:

1. **確認**: 該当箇所のコードを Read で確認し、コメントの指摘が現在のコードに対して有効か検証する
   - コメントのファイルパス・行番号から該当箇所を特定する
   - 指摘が既に解消済み（前のコミットや前の修正で対応済み）の場合はスキップし、理由を報告する
2. **修正**: Edit で最小限のコード修正を行う
3. **リント**: `make lint` を実行する。失敗したらスコープ内で修正してリトライする
4. **コミット**: 1コメント = 1コミット

```bash
git add <修正ファイル>
git commit -m "<type>: <修正内容の説明>"
```

#### コミットメッセージのルール

- 何を修正したかを具体的に記述する（例: `fix: add null check for user input validation`）
- `fix review comment`、`address PR feedback`、`レビュー対応` のような曖昧な表現は禁止
- コメントIDやPR番号をメッセージに含めない
- type: `fix`, `refactor`, `style`, `test`, `docs` など

コメントの意図が不明確な場合はユーザーに確認する。

### Step 6: テスト実行

全修正完了後:

```bash
make test
```

テストが失敗した場合はユーザーに報告し、修正するか確認する。

### Step 7: サマリーとプッシュ

```
## レビュー対応完了

### 修正したコメント
- [commit hash] @reviewer: path/to/file.py:42 — null チェック追加
- [commit hash] @reviewer: path/to/handler.py:15 — エラーハンドリング追加

### スキップしたコメント
- @reviewer: 「...」 — 理由: 質問のため（コード変更不要）
- @reviewer: 「...」 — 理由: 既に対応済み

### テスト結果
- 結果: PASS / FAIL

変更をプッシュしますか？
```

ユーザーが承認した場合:

```bash
git push
```

### Step 8: レビューコメントへの返信

プッシュ後、修正した各コメントに対して返信を投稿する。

各コミットのURLを組み立てる:

```bash
# コミットハッシュからURL: https://github.com/{owner}/{repo}/commit/{hash}
git log --oneline HEAD~N..HEAD  # N = 修正コミット数
```

修正した各コメントの comment_id を使って返信する:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_num}/comments/{comment_id}/replies \
  --method POST \
  -f body="修正しました。 [{short_hash}](https://github.com/{owner}/{repo}/commit/{full_hash})"
```

## 注意事項

- スコープガード: PR変更範囲外のファイルは原則修正しない
- 各修正前に実際のコードを確認してから修正する（コメントを鵜呑みにしない）
- リント失敗は修正してからコミットする
- コメントの意図が不明確な場合はユーザーに確認する
