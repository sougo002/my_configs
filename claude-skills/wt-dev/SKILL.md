---
name: wt-dev
description: worktree作成→ドキュメント化→設計→実装→セルフレビュー2回までユーザー介入なしで完走するハンズオフ開発スキル。
allowed-tools: Read, Grep, Glob, Edit, Write, Task, EnterWorktree, ExitWorktree, Bash(git fetch*), Bash(git status*), Bash(git diff*), Bash(git log*), Bash(git rev-parse*), Bash(git branch*), Bash(git add*), Bash(git commit*), Bash(make lint*), Bash(make test*), Bash(mkdir -p*), Bash(ls*), Bash(test -f*), Bash(ln -s*), Bash(cp*), Bash(bash ~/.claude/skills/wt-start/apply-deps.sh*), Skill(self-review)
---

# ハンズオフ開発スキル

**出力は常に日本語で行う。**

## ワークフロー

### Step 1: Worktree 作成

1. **対象リポジトリの中に cwd があることを確認する**。`EnterWorktree` は git リポジトリ内で呼ぶ必要がある。cwd がリポジトリのルートでない場合は対象リポジトリに入ってから進める。
2. **`EnterWorktree({name: "<type>/<簡潔な説明>"})` で worktree を作成する**。name は作業内容から決める。これでセッションの cwd が worktree に切り替わり、以降の Bash/Read/Edit は worktree 上で走る。ブランチも `<type>/<名前>` で直接作られるため `git branch -m` でのリネームは不要。
   - 既定の base ref は `fresh` で `origin/<デフォルトブランチ>` 起点。デフォルトブランチが統合先と異なる場合のみ `worktree.baseRef` 設定で調整する。
3. **依存ファイルを補完する**。`EnterWorktree` は素の git worktree を作るだけで、`.gitignore` 対象の `.venv` / `node_modules` / `.env` / 認証情報などは持ち込まれない。`bash ~/.claude/skills/wt-start/apply-deps.sh` を実行し、対象リポジトリの `.cursor/worktrees.json` にある `setup-worktree-unix`（なければ `setup-worktree`）を適用する。
   - `DONE:<name>` なら完了。
   - `NO_CONF` / `NO_SETUP` / `INVALID_CONF:<detail>` の場合は補完せず、その旨を報告して進む。
   - **コンテナ起動（`wt watch`）はしない**。`make lint` / `make test` はコンテナ無しで通る前提。コンテナが必要になったらユーザーが自分で `/wt-start` を実行する。

### Step 2: 記録先の決定

ローカルにドキュメントを 1 本作成して記録する。

- メモリ `documents.md` を Read し、置き場規約 `a/<topic>/` 配下に従う。topic 名は作業内容から決める
- `ls a/` で既存 topic を確認し、関連する既存 topic があれば再利用、なければ新規作成
- ファイルはこのスキル実行ごとに新規 1 本（既存ファイルへの追記はしない）

ここでは**記録先を決めるだけ**。本文は Step 6 でまとめて 1 回書く。途中経過を逐次追記しない。

### Step 3: 設計

- 複雑な機能なら `Task` でサブエージェントを呼んで設計案を生成する

### Step 4: 実装

- 設計に従い実装する
- `make lint` と `make test` を実行して通す
- 実装が大きい場合は途中でコミットを積んでよい

### Step 5: セルフレビュー × 2

`/self-review` スキルを 2 回実行する。各回、検出された所見を修正・コミットする。

### Step 6: 記録と完了サマリー

まず Step 2 で決めたローカルファイルに、作業内容を**数行で簡潔に**記録する。

- 目的: なぜこの対応が必要か（解決したい課題）
- 方針: どう考えてどうアプローチしたか（採った判断・捨てた選択肢）
- 変更: 何をしたか（主な変更点）

**書き方のルール**:
- 人が読んで「何のために・何を考えて・どうしたのか」が一読で分かることだけを目的とする
- 各項目 1〜2 行。worktree / ブランチ名、レビューの経緯、進行ログは書かない
- diff を読めば分かる詳細は書かない

その上で、セッションには以下の完了サマリーを提示する:

```
## /wt-dev 完了

### worktree
<worktreeのパス>

### 記録先
<作成したローカルファイル>

### コミット
<git log --oneline <base ref>..HEAD の出力>
```

PR 作成・最終コミット取りまとめは **このスキルでは行わない**。
