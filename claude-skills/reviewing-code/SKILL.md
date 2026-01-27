---
name: reviewing-code
description: developmentブランチとの差分をレビューし、品質・セキュリティ・保守性を評価します。PRやコード変更のレビュー時に使用。
tools: Read, Grep, Glob, Bash
---

# コードレビュースキル

**出力は常に日本語で行う。**

## ベースブランチ

**重要: 常に `development` ブランチと比較する。`main` ではない。**

gitStatusコンテキストで "Main branch for PRs" と表示されていても無視すること。このスキルでは常に `development` をベースブランチとして使用する。

```bash
git diff --name-status development
git diff development
```

## ワークフロー

以下のチェックリストをコピーして進捗を管理:

```
レビュー進捗:
- [ ] Step 1: 差分の概要確認 (git diff --stat)
- [ ] Step 2: 詳細な変更内容を確認 (git diff)
- [ ] Step 3: アーキテクチャ・設計の確認
- [ ] Step 4: セキュリティの確認
- [ ] Step 5: コード品質の評価
- [ ] Step 6: テストカバレッジの確認
- [ ] Step 7: 構造化されたフィードバックを提供
```

## レビュータイプ

| タイプ | フォーカス | 使用場面 |
|--------|-----------|----------|
| Full | 全観点 | PRのデフォルト |
| Security | 脆弱性、認証、入力検証 | 機密性の高い機能 |
| Performance | 効率、ボトルネック | データ処理の多いコード |
| Maintainability | 可読性、構造 | リファクタリングPR |

## レビュー優先度

### Critical（マージ前に必ず修正）
- セキュリティ脆弱性（インジェクション、XSS、認証バイパス）
- データ消失リスク
- マイグレーションなしの破壊的変更

### High（修正すべき）
- 設計原則違反（SOLID、DRY）
- エラーハンドリングの欠如
- パフォーマンスボトルネック

### Medium（修正を検討）
- コードスタイルの不統一
- テスト不足
- 技術的負債

### Low（提案）
- 命名の改善
- ドキュメントの不足
- 軽微なリファクタリング

## 詳細ガイド

- **セキュリティレビュー**: [SECURITY.md](SECURITY.md) を参照
- **アーキテクチャレビュー**: [ARCHITECTURE.md](ARCHITECTURE.md) を参照
- **レビューチェックリスト**: [CHECKLIST.md](CHECKLIST.md) を参照

## 出力形式

レビュー結果は `./a/self-review/pr-review-<ブランチ名>.md` に保存:

```markdown
## サマリー
- 変更ファイル数: X
- 行数: +XXX / -XXX
- スコープ: [frontend/backend/database/config]

## 評価
- グレード: [S/A+/A/B+/B/C+/C/D]
- マージ推奨: [Ready/軽微な修正が必要/修正が必要/要再作業]

## 所見

### 良い実装
- [具体例]

### Critical Issues
- [セキュリティリスク、バグ]

### Warnings
- [設計上の問題、パフォーマンス]

### Suggestions
- [将来的な改善提案]

## 推奨アクション
1. 即時対応: [重大な修正]
2. 短期: [重要な改善]
3. 長期: [技術的負債]
```

## 注意事項

- レビューはPR作成前に実行する（作成後ではなく）
- 変更のコンテキストと意図を考慮する
- 建設的で実行可能なフィードバックを提供する
- 所見は重大度順に優先度付けする