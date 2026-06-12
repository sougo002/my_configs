---
name: approve
description: PRを承認（approve）する。コメントをドラフトしてユーザー確認後、`gh pr review --approve` で投稿する。
allowed-tools: Read, Bash(gh pr view *), Bash(gh pr review *), Bash(gh api *), Bash(git *)
---

# PR 承認スキル

**出力は常に日本語で行う。**

## 入力形式

PR URL を引数として受け取る: `/approve https://github.com/<owner>/<repo>/pull/<number>`

引数が省略された場合は、現在のブランチに紐づく PR を `gh pr view --json url,number` で解決する。

## ワークフロー

### Step 1: コンテキスト収集

会話上のコンテキストを最大限に活用する（直前のレビューや動作確認の内容がそのまま承認コメントの材料になる）。追加で以下を取得:

```bash
gh pr view <pr_url> --json title,body,headRefName,baseRefName,author
```

関連する review-pr レポートがあれば参照:
- `<workspace>/pr-review/reports/<repo>--<safe-branch>.md`

### Step 2: コメントのドラフト

下記の骨子でドラフトする。**投稿前に必ずユーザーに見せて確認する**。ユーザーの修正指示を受けたら反映し、再度見せる。これを OK が出るまで繰り返す。

```
LGTM <ランダムな絵文字1つ>

## 動作確認（任意セクション）
- <検証済みの項目を具体的に箇条書き>

## 補足（任意セクション)
- <PR スコープ外で別対応が必要な事実>
```

#### スタイルルール（厳守）

- 1行目は `LGTM` + 絵文字1つ。絵文字は会話ごとに変える
- `## 動作確認` と `## 補足` は任意セクション。**ユーザーが明示的に指示したとき、または必要だと判断したときだけ**付ける。どちらもなければ `LGTM` 1行だけでよい（「（任意セクション）」の表記は投稿文には含めない）
- `## 動作確認` は**具体的に何を確認したか**だけを書く。
- 締めの感想行（「ありがとうございます」「引き続きよろしく」等）は書かない
- 「worktree で動かした」「ローカルで compose を立てた」など**内部の作業手順**は書かない。確認した**事実**だけを書く
- 指摘する際の口調はフラットに。「推奨します」「ご検討ください」のような外向け表現は避け、「〜しましょう」「〜がよさそう」程度に留める
- 「補足」に入れるのは PR スコープ外で別対応が必要な事実（バグ・負債）のみ。PR 本体の議論は含めない

### Step 3: 投稿

ユーザーから明示的な OK を得たら投稿する。HEREDOC でコメント本文を渡す:

```bash
gh pr review <pr_url> --approve --body "$(cat <<'EOF'
LGTM [絵文字]

[任意セクションがあればここに]
EOF
)"
```

### Step 4: 投稿結果の確認

```bash
gh pr view <pr_url> --json reviews --jq '.reviews[-1] | {author: .author.login, state, submittedAt}'
```

`state` が `APPROVED` になっていることを確認し、ユーザーに結果を報告する。

## 注意事項

- ユーザーの明示的な OK なしに投稿しない（「よき」「OK」「問題なし」などが該当）
- ドラフトは過度に装飾しない。動作確認項目が1行だけでも、それが事実ならそれでよい
- 懸念・Critical があって approve すべきでないと判断したときは、approve せずユーザーに相談する
- 補足を書く場合、リンク先行番号は `<path>:<line>` 形式で具体的に。曖昧な「〜あたり」は避ける
