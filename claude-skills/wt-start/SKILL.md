---
name: wt-start
description: 指定または推定した worktree に依存ファイルを補完しコンテナを起動する。引数でパス・ブランチ名などを渡せる。
allowed-tools: Read, AskUserQuestion, Bash(git rev-parse*), Bash(git worktree*), Bash(git ls-files*), Bash(git status*), Bash(git branch*), Bash(ln -s*), Bash(cp*), Bash(mkdir -p*), Bash(test*), Bash(ls*), Bash(find*), Bash(cat*), Bash(wt*), Bash(bash ~/.claude/skills/wt-start/apply-deps.sh*)
disable-model-invocation: true
---

# wt-start

**出力は常に日本語で行う。**
このskillはproject固有の情報を持たない。依存ファイルのセットアップ定義は各リポジトリの `.cursor/worktrees.json` にある。

## 入力形式

`/wt-start` の後ろに `TARGET` を渡せる（省略可）。worktree のパス、ブランチ名、ディレクトリ名の一部、`main` / `レビュー` など。省略時は Step 0 で cwd と会話から自動判定する。

## Step 0: 起動先 worktree の解決

`$WT`（起動先の絶対パス）を確定する。会話コンテキストで判断する。

### 0a. リポジトリの特定

cwd・会話で触れているリポジトリから、対象 git リポジトリを特定する。特定できなければユーザーに聞く。

```bash
git -C <path> worktree list
```

先頭行のパスを `$MAIN` とする。

### 0b. `TARGET` がある場合

1. **絶対パス** → 存在し `git -C` で worktree として有効なら `$WT`
2. **ブランチ名**（`feat/...` など）→ `git worktree list` のブランチ列と照合
3. **ディレクトリ名の一部** → worktree パスの basename と照合
4. **レビュー系の指示** → 会話でレビューしていた PR・ブランチ・パスを優先し、`pr-review/worktrees/` 配下を探す。会話に PR URL やブランチがあればそれに合わせる
5. **`main` / `メイン`** → `$WT=$MAIN`

複数一致・不一致なら候補を短く示しユーザが選ぶ。

### 0c. `TARGET` がない場合（自動判定）

次の順で手がかりを使う。

1. cwd が非メイン worktree → そのパスを `$WT`
2. 会話の直近コンテキストから一意に特定できる worktree
3. cwd がメイン worktree で上記で決まらない → `$WT=$MAIN`
4. 一意に決まらない → `git worktree list` の中から最適なものを提示してユーザが選ぶ

## Step 1: 依存ファイル補完

```bash
cd "$WT" && bash ~/.claude/skills/wt-start/apply-deps.sh "$WT"
```

- `DONE:<name>` なら完了。Step 2 に進む
- `SAME_PATH` → メイン worktree で起動する場合のみ。Step 2 へ
- `NO_CONF` / `NO_SETUP` / `INVALID_CONF:<detail>` の場合のみ、以下の調査フローに切り替える:
  - `$MAIN` に存在し `$WT` に存在しない gitignore 対象（`.env*` / `.venv` / `node_modules` / 認証情報など）を洗い出す
  - 各ファイル/ディレクトリを symlink（実体が大きい・watch不要なもの）または cpで補完する
  - 補完した内容をユーザーに報告し、次回以降のために対象リポジトリの `.cursor/worktrees.json` へ追加することを提案する

## Step 2: 起動

`$WT` で `wt watch -y` を実行する。これはファイル監視を続ける常駐プロセスである。

完了報告には **起動した worktree のパスとブランチ名** を必ず含める。
