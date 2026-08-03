---
name: issue
description: 会話を元にissueをドラフトし、ユーザー確認後に作成する。既存issueの編集・コメント投稿/追記・sub-issue化・アサイン・Project追加・sub-issue一覧もできる汎用のGitHub issue操作スキル。issueを作りたい/編集したい/コメントしたい/sub-issue化したい/アサインしたい/Projectに追加したい場面で使う。
allowed-tools: Read, AskUserQuestion, Bash(gh issue list *), Bash(gh repo view *), Bash(python3 ~/.claude/skills/issue/scripts/create.py *), Bash(python3 ~/.claude/skills/issue/scripts/edit.py *), Bash(python3 ~/.claude/skills/issue/scripts/comment.py *), Bash(python3 ~/.claude/skills/issue/scripts/link_subissue.py *), Bash(python3 ~/.claude/skills/issue/scripts/assign.py *), Bash(python3 ~/.claude/skills/issue/scripts/add_to_project.py *), Bash(python3 ~/.claude/skills/issue/scripts/list_subissues.py *)
---

# Issue 操作スキル

**出力は常に日本語で行う。**

リポジトリ非依存の汎用 issue 操作スキル。会話からの作成のほか、編集・sub-issue化・アサイン・Project追加を `scripts/` 配下の python script で行う。

## 入力形式

```
/issue
/issue <一行の補足や強調したい論点>
```

引数があればドラフトのシードとして使う。なければ会話コンテキストから題材を抽出する

## ワークフロー

### Step 1: コンテキスト収集 & 重複チェック

会話上の議論をそのまま材料にする。追加で以下を取得

```bash
# 対象リポジトリの確認（カレントリポジトリを既定とする）
gh repo view --json nameWithOwner,defaultBranchRef

# 同趣旨のIssueがないかキーワードで軽く確認
gh issue list --search "<キーワード>" --state all --limit 10
```

複数リポジトリにまたがる議論だった場合のみ、どのリポジトリに立てるか `AskUserQuestion` で確認する。
重複候補が見つかったらユーザーに提示し、新規作成を続けるか中断するか確認する。

### Step 2: テンプレート探索

以下を順に Read で確認し、最初に見つかったものを採用する:

- `.github/ISSUE_TEMPLATE/` 配下の `*.md` / `*.yml`（複数あれば内容を見て最も近いものを選ぶ）
- `.github/ISSUE_TEMPLATE.md`
- `ISSUE_TEMPLATE.md`

テンプレートがない場合のデフォルト構成:

```markdown
## 概要
<1〜2行で何の問題か / 何をしたいか>

## 背景・経緯
<議論や観察の要点を箇条書き>

## 期待する動作 / ゴール
<どうなれば解決か>

## 補足
<関連するコード位置・参考リンクなど。なければ省略>
```

### Step 3: ドラフト提示

タイトルと本文をドラフトしてユーザーに見せる。修正指示が出たら反映して再提示し、OKが出るまで繰り返す。

- 本文は極力短くする。冗長な説明・前置き・まとめは削る
- 箇条書きで端的に書く

### Step 4: 投稿

ユーザーから明示的なOKを得たら作成する。本文は一時ファイルに書き出し `create.py` に渡す（エスケープ問題を回避）:

```bash
python3 ~/.claude/skills/issue/scripts/create.py \
  --repo OWNER/REPO \
  --title "<タイトル>" \
  --body-file /tmp/issue_body.md
```

作成結果は `{"number":.., "url":..}` の JSON で返る。

### Step 5: 結果報告

作成された Issue URL をユーザーに報告する。

## 操作リファレンス

すべて `~/.claude/skills/issue/scripts/` 配下。本文は `--body-file` か stdin で渡す。

### 作成（create.py）

```bash
python3 ~/.claude/skills/issue/scripts/create.py \
  --repo OWNER/REPO --title "タイトル" --body-file body.md \
  [--label ラベル]... [--assignee ユーザー]... \
  [--parent 親issue番号] \
  [--add-to-project --project-owner OWNER --project-number 番号]
```

- `--parent` 指定で作成後に GraphQL `addSubIssue` を実行し、親issueの sub-issue として紐付ける。
- `--add-to-project` 指定時のみ作成後に Project へ追加。

### 編集（edit.py）

```bash
python3 ~/.claude/skills/issue/scripts/edit.py \
  --repo OWNER/REPO --number 123 [--title "新タイトル"] [--body-file new_body.md]
```

### コメント投稿 / 追記（comment.py）

```bash
# 新規投稿（{"id":.., "url":..} を返す）
python3 ~/.claude/skills/issue/scripts/comment.py \
  --repo OWNER/REPO --number 123 --body-file body.md

# 既存コメントを差し替え
python3 ~/.claude/skills/issue/scripts/comment.py \
  --repo OWNER/REPO --comment-id 456 --body-file body.md

# 既存コメントの末尾に追記
python3 ~/.claude/skills/issue/scripts/comment.py \
  --repo OWNER/REPO --comment-id 456 --append --body-file add.md
```

新規投稿で返る `id` を控えておけば、以降は `--comment-id` で同じコメントを更新・追記できる。

### sub-issue 紐付け（link_subissue.py）

```bash
python3 ~/.claude/skills/issue/scripts/link_subissue.py \
  --repo OWNER/REPO --parent 100 --child 101 --child 102
```

GraphQL で nodeID を解決し `addSubIssue` を実行する。

### アサイン（assign.py）

```bash
python3 ~/.claude/skills/issue/scripts/assign.py \
  --repo OWNER/REPO --number 123 [--number 124]... --assignee ユーザー
```

### Project 追加（add_to_project.py）

```bash
python3 ~/.claude/skills/issue/scripts/add_to_project.py \
  --owner OWNER --project-number 番号 --url ISSUE_URL [--url ...]
```

冪等。Project 操作には `project` スコープが必要。

### sub-issue 一覧（list_subissues.py）

```bash
python3 ~/.claude/skills/issue/scripts/list_subissues.py --repo OWNER/REPO --parent 100
```

## 注意事項

- 本文は file・stdin で渡し、HEREDOC のエスケープ問題を避ける。
- 複数 issue の作成・アサインは可能な限り並列実行する。
