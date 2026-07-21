---
name: wt-start
description: 現在のworktreeに依存ファイルを補完し、`wt watch -y` でコンテナを起動する。
allowed-tools: Read, Bash(git rev-parse*), Bash(git worktree*), Bash(git ls-files*), Bash(ln -s*), Bash(cp*), Bash(mkdir -p*), Bash(test*), Bash(ls*), Bash(find*), Bash(cat*), Bash(wt*), Bash(bash ~/.claude/skills/wt-start/apply-deps.sh*)
disable-model-invocation: true
---

# wt-start

**出力は常に日本語で行う。**
このskillはproject固有の情報を持たない。project固有のsymlink/cp定義は `~/.claude/memory/worktree-deps.conf` 側にある。

## Step 1: 依存ファイル補完

`bash ~/.claude/skills/wt-start/apply-deps.sh` を実行する。

- `DONE:<name>` なら完了。Step 2 に進む。
- `SAME_PATH` / `NO_CONF` / `UNKNOWN_PROJECT:<name>` の場合のみ、以下の調査フローに切り替える:
  - `$MAIN` に存在し `$WT` に存在しない gitignore 対象（`.env*` / `.venv` / `node_modules` / 認証情報など）を洗い出す
  - 各ファイル/ディレクトリを symlink（実体が大きい・watch不要なもの）または cp（`.env` 系など watch で変更検知が必要なもの）で補完する
  - 補完した内容をユーザーに報告し、次回以降のために `~/.claude/memory/worktree-deps.conf` への `[<project名>]` セクション追記を提案する（`link <relpath>` / `copy <relpath>` の書式）

## Step 2: 起動

`$WT` で `wt watch -y` を `run_in_background: true` で実行する。これはファイル監視を続ける常駐プロセスである。
