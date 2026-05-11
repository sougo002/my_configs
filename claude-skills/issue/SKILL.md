---
name: issue
description: 会話を元にissueをドラフトし、ユーザー確認後に `gh issue create` で作成する
allowed-tools: Read, Bash(gh issue *), Bash(gh repo view *), Bash(gh api *), AskUserQuestion
disable-model-invocation: true
---

# Issue 作成スキル

**出力は常に日本語で行う。**

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

ユーザーから明示的なOKを得たら作成する。HEREDOCで本文指定:

```bash
gh issue create \
  --title "<タイトル>" \
  --body "$(cat <<'EOF'
<本文>
EOF
)"
```

### Step 5: 結果報告

作成された Issue URL をユーザーに報告

```bash
gh issue view <issue番号> --json url,number,title --jq '{number, title, url}'
```
