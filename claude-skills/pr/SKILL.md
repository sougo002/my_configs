---
name: pr
description: 現ブランチをpushし、PRテンプレートに沿って本文を書きdraft PRを作成する
allowed-tools: Read, Bash(git status*), Bash(git log*), Bash(git diff*), Bash(git push*), Bash(git rev-parse*), Bash(git branch*), Bash(git fetch*), Bash(gh pr *), Bash(gh repo view *)
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

### Step 2: push

未pushまたは差分があれば push

```bash
git push -u origin <ブランチ名>
```

### Step 3: テンプレート探索 & 本文作成

以下を順に Read で確認し、最初に見つかったものを採用する

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template.md`
- `PULL_REQUEST_TEMPLATE.md`

タイトルと、テンプレートの各セクションを1〜2行で埋めた本文を書く。コミット履歴と差分から事実だけを書き推測は書かない

### Step 4: draft PR作成

```bash
gh pr create --draft \
  --title "<タイトル>" \
  --body "$(cat <<'EOF'
<本文>
EOF
)"
```

### Step 5: 結果報告

作成された PR URL を報告する。

```bash
gh pr view --json url,number,title --jq '{number, title, url}'
```
