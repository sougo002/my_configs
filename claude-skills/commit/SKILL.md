---
name: commit
description: 変更を分析し、論理単位で分割してコミットする
allowed-tools: Read, Bash(git status*), Bash(git diff*), Bash(git log*), Bash(git add*), Bash(git restore*), Bash(git commit*)
disable-model-invocation: true
---

# コミット作成スキル

**出力は常に日本語で行う。**

## ワークフロー

### Step 1: 状態確認

```bash
git status
git diff
git log -n 5 --oneline
```

変更が無ければ中止

### Step 2: 論理単位の判定

1つのコミットで1つの責務になるようになるべく小さく分割する

### Step 3: コミット実行

特定のファイル名を明示して `git add` した後、Conventional Commits に従って日本語で簡潔にメッセージを書きコミットする。`git add -A` や `git add .` は使用しない。

```bash
git add <ファイル1> <ファイル2>
git commit -m "$(cat <<'EOF'
<件名>

<本文>
EOF
)"
```
