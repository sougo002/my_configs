---
name: wt-dev
description: worktree作成→ドキュメント化→設計→実装→セルフレビュー2回までユーザー介入なしで完走するハンズオフ開発スキル。
allowed-tools: Read, Grep, Glob, Edit, Write, Task, EnterWorktree, ExitWorktree, Bash(git fetch*), Bash(git status*), Bash(git diff*), Bash(git log*), Bash(git rev-parse*), Bash(git branch*), Bash(git add*), Bash(git commit*), Bash(make lint*), Bash(make test*), Bash(mkdir -p*), Bash(ls*), Bash(test -f*), Bash(ln -s*), Bash(cp*), Skill
disable-model-invocation: true
---

# ハンズオフ開発スキル

**出力は常に日本語で行う。**

## ワークフロー

### Step 1: Worktree 作成

プロジェクトメモリ `~/.claude/projects/<project-slug>/memory/worktree.md` を Read し、記載された手順に従って worktree 作成と依存関係セットアップを実行する。

worktree 名は `<type>/<簡潔な説明>` 形式で作業内容から決める。

### Step 2: ドキュメント作成

プロジェクトメモリ `~/.claude/projects/<project-slug>/memory/documents.md` を Read し、記載された置き場規約（`a/<topic>/` 配下）に従ってドキュメントを作成する。topic 名は作業内容から決める。

**topic ディレクトリの扱い**:
- まず `ls a/` で既存 topic を確認する
- 作業内容と関連する既存 topic があれば **その topic ディレクトリを再利用** する
- 関連する既存 topic がなければ **新規作成** する

**ファイル**:
- topic ディレクトリが既存・新規どちらでも、**このスキル実行ごとに新規ファイルを 1 本切る**
- 既存ファイルへの追記は行わない
- ファイル名は作業内容から決める
- 内容は作業内容そのもの。Step 3〜5 の進行に合わせて同じファイルに追記していく

### Step 3: 設計

- 必要なら `Task` でサブエージェントを呼んで設計案を生成する（複雑な機能の場合）
- 設計内容を Step 2 のファイルに反映する

### Step 4: 実装

- 設計に従い実装する
- `make lint` と `make test` を実行して通す
- 実装が大きい場合は途中でコミットを積んでよい

### Step 5: セルフレビュー × 2

`/self-review` スキルを 2 回実行する。

**Round 1**:
1. `/self-review` を実行する
2. 検出された所見を修正・コミットする（self-review 側で完結する）
3. Step 2 のファイルに「レビュー Round 1」セクションを追記する（検出された所見と対応の要約）

**Round 2**:
1. `/self-review` を再度実行する
2. 検出された所見を修正・コミットする
3. Step 2 のファイルに「レビュー Round 2」セクションを追記する

### Step 6: 完了サマリー

最後に以下を提示する:

```
## /wt-dev 完了

### worktree
<worktreeのパス>

### ドキュメント
<a/<topic>/ 配下に作成・更新したファイル>

### コミット
<git log --oneline development..HEAD の出力>
```

PR 作成・最終コミット取りまとめは **このスキルでは行わない**。
