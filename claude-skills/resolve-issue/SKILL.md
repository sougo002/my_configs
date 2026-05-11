---
name: resolve-issue
description: GitHub Issue を解決する。実装系（機能追加・バグ修正・リファクタ）と調査系で分岐する。Issue 番号を指定して使用。
allowed-tools: Read, Grep, Glob, Bash, Task, Edit, Write, AskUserQuestion, ExitWorktree, Skill
---

# Issue解決スキル

**出力は常に日本語で行う。**

## 使用方法

```
/resolve-issue #123
/resolve-issue 123
/resolve-issue https://github.com/owner/repo/issues/123
```

## ワークフロー

### Step 1: Issue 取得と種別判定

```bash
gh issue view <issue番号> --json title,body,labels,assignees,comments
```

Issue 内容とラベル（`bug`, `feature`, `investigation` 等）から種別を判定する:

- **実装系**: 機能追加・バグ修正・リファクタ → 実装系フロー
- **調査系**: 調査・分析 → 調査系フロー

判定が曖昧な場合は `AskUserQuestion` で確認する。

## 実装系フロー

### 作業内容化と承認

Issue 内容を以下の形式で **作業内容** にまとめて提示する:

- 目的・スコープ・スコープ外
- エッジケース・前提条件
- 影響リポジトリ・想定変更ファイル群
- 設計方針の概要

`AskUserQuestion` で「この内容で進める / 修正する / 中止する」の合意を取る。

### /wt-dev 起動

合意後、`Skill` ツールで `/wt-dev` を起動する。

### /pr 起動

`/wt-dev` 完了後、worktree 内で `Skill` ツールで `/pr` を起動する。本文には `Resolves #<Issue番号>` を含める。

### Worktreeから退出

```
ExitWorktree(action="keep")
```

## 調査系フロー

### 調査範囲の確認

Issue から調査範囲・期待されるアウトプットを抽出し、`AskUserQuestion` で「この範囲で進める / 修正する / 中止する」の合意を取る。

### 調査実施

合意した範囲でコード調査・分析を行う。コード変更は行わない。

### 結果のコメント投稿

調査結果を Markdown でまとめ、Issue にコメント投稿する。

```bash
gh issue comment <issue番号> --body "$(cat <<'EOF'
## 調査結果

<内容>

## 結論

<結論・推奨アクション>
EOF
)"
```
