---
name: pr
description: 現ブランチをpushし、PRテンプレートに沿って本文を書きdraft PRを作成する
allowed-tools: Read, Skill(make-pr-easy-to-review), Bash(git status*), Bash(git log*), Bash(git diff*), Bash(git push*), Bash(git rev-parse*), Bash(git branch*), Bash(git fetch*), Bash(gh pr *), Bash(gh repo view *)
disable-model-invocation: true
---

# PR 作成スキル

**出力は常に日本語で行う。**

## ワークフロー

### Step 1: ブランチ状態の確認

```bash
git rev-parse --abbrev-ref HEAD
git status
git log <base>...HEAD --oneline
git diff <base>...HEAD
```

`main`/`development` ブランチの場合は中止。ベースブランチは GitHub のデフォルトブランチを既定とする (`gh repo view --json defaultBranchRef`)。

### Step 2: PR整形（make-pr-easy-to-review）

push 前に `Skill` ツールで `make-pr-easy-to-review` を実行し、レビュアーがPRを理解しやすくなるよう整える。

- 得られたレビュアー向けガイダンス（TL;DR、core と mechanical/生成ファイルの分離、リスク・移行順序・テスト範囲の明示など）は Step 4 の本文作成に反映する。
- コミット履歴の書き換え（squash/並べ替え等）は**ユーザーが同意した場合のみ**行う（スキル側のガードに従う。挙動は変えない）。

### Step 3: push

未pushまたは差分があれば push

```bash
git push -u origin <ブランチ名>
```

### Step 4: テンプレート探索 & 本文作成

以下を順に Read で確認し、最初に見つかったものを採用する

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template.md`
- `PULL_REQUEST_TEMPLATE.md`

タイトルと、テンプレートの各セクションを以下のルールに沿って書く。

### 書き方のルール

- コミット履歴と差分から事実だけを書き推測は書かない
- どこに何を追加したかを抽象 → 具体の順で書く
- 差分から読めることを冗長に書かない
- Step 2 で得たレビュアー向けガイダンス（TL;DR、core と mechanical/生成ファイルの分離、リスク・移行順序・テスト範囲）をテンプレートの該当セクションに反映する

### Step 5: draft PR作成

```bash
gh pr create --draft \
  --title "<タイトル>" \
  --body "$(cat <<'EOF'
<本文>
EOF
)"
```

### Step 6: 結果報告

作成された PR URL を報告する。

```bash
gh pr view --json url,number,title --jq '{number, title, url}'
```
