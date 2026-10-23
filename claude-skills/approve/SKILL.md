---
name: approve
description: PRを承認（approve）する。コメントをドラフトしてユーザー確認後、`gh pr review --approve` で投稿する。
allowed-tools: Read, Bash(gh pr view *), Bash(gh pr review *), Bash(gh api *)
---

# PR 承認スキル

出力は常に日本語で行う。

## 入力形式

PR URL を引数として受け取る: `/approve https://github.com/<owner>/<repo>/pull/<number>`

引数が省略された場合は、現在のブランチに紐づく PR を `gh pr view --json url,number` で解決する。

## ワークフロー

### Step 1: コンテキスト収集

会話上のコンテキストを最大限に活用する（直前のレビューや動作確認の内容が承認コメントの材料になる）。追加で以下を取得:

```bash
gh pr view <pr_url> --json title,body,headRefName,baseRefName,author
```

関連する review-pr レポートがあれば参照:
- `<workspace>/pr-review/reports/<repo>--<safe-branch>.md`

レビュー後に承認する場合は、ローカルに残っている指摘を確認する:

- 参照するのは、会話上のレビュー結果と、ローカルのレビューレポート（`<workspace>/pr-review/reports/` 配下）
- 残っている指摘を一覧にする
- 一覧を「対応済み」「対応不要」「残す」に分け、ユーザーに確認する
- ユーザーが残すと判断した指摘があれば、承認を見送るか、承認の上で残すかをユーザーに確認する
- この確認が終わるまで、ドラフトは作らない

### Step 2: コメントのドラフト

下記の形でドラフトする。投稿前に必ずユーザーに見せて確認する。ユーザーの修正指示を受けたら反映し、再度見せる。OK が出るまで繰り返す。

```
LGTM <ランダムな絵文字1つ>
```

ユーザーがコメント文を渡したときは、その文を `LGTM` 行の下に追加してドラフトを作る。渡された文は勝手に書き換えない。

#### スタイルルール（厳守）

- 1行目は `LGTM` + 絵文字1つ。絵文字は会話ごとに変える
- 締めの感想行は書かない
- 内部の作業手順は書かない
- 指摘する際の口調はフラットに。「推奨します」「ご検討ください」のような外向け表現は避け、「〜がよさそう」程度に留める

### Step 3: 投稿

ユーザーから明示的な OK を得たら投稿する。HEREDOC でコメント本文を渡す:

```bash
gh pr review <pr_url> --approve --body "$(cat <<'EOF'
LGTM [絵文字]

[ユーザーが渡したコメントがあればここに]
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
- ドラフトは過度に装飾しない
- 懸念・Critical があって approve すべきでないと判断したときは、approve せずユーザーに相談する
