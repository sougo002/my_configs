# レビュー作業の対応表

| # | やること | 出力先（reports/<repo>--<safe-branch>/ 配下） |
|---|---------|------------------------------------------|
| 1 | PRの目的と「このPRで変わったこと」を整理する（Step 1） | 00-overview.md |
| 2 | 変更ファイルを観点別に分類する（Step 2、deep のみ） | 01-file-classification.md |
| 3 | 5観点で並列レビューする（Step 3-4） | 02-review-results.md |
| 4 | 指摘を実コードで検証し、採用・修正・却下・実行確認へ回す・既存の問題に振り分ける（Step 3-4） | 03-validation.md |
| 5 | 検証済みの指摘を統合し、評価・所見・処理フローをまとめる（Step 5・Step 8） | 06-summary.md |
| 6 | 実行確認が必要な項目を確認する（Step 6） | 04-runtime-check.md |
| 7 | UXペルソナ検証（ux オプション時のみ、Step 7） | 05-ux-persona.md、ux-artifacts/<persona>/ |
| 8 | 専門観点の追加レビュー（必要時のみ） | 02-1-<観点>.md など |

## 追加でやること

（依頼が追加されたら、ここに 1 行ずつ追記する）
