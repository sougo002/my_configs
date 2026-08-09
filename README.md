# my_configs

個人用の設定ファイル管理リポジトリ

## セットアップ

```bash
./setup_mac.sh
```

### マシン固有の設定

git管理下に置きたくない設定はローカルファイルに書く。`~/.gitconfig` は `~/.gitconfig.local` を、`.zshrc` は `~/.zshrc.local` を、それぞれ存在すれば読み込む。セットアップ時にサンプルが配置されるので中身を書き換える。

## 内容

- **Brewfile**: Homebrew パッケージ
- **dotfiles/**: シェル設定、`$XDG_CONFIG_HOME` 配下の設定
- **claude-skills/**: Claude Code カスタムスキル
