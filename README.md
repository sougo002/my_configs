# my_configs

個人用の設定ファイル管理リポジトリ

## セットアップ

エージェントに以下を入力する。

```
README のエージェント向け手順に従ってセットアップして
```

### エージェント向け手順

1. `./setup_mac.sh` を実行する
2. ユーザーにメールアドレスを聞いて、`~/.gitconfig.local` の `user.email` に書く

## 内容

- **Brewfile**: Homebrew パッケージ
- **dotfiles/**: シェル設定、`$XDG_CONFIG_HOME` 配下の設定
- **claude-skills/**: Claude Code カスタムスキル
