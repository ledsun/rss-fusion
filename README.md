# RSS Fusion

複数の RSS / Atom フィードを統合し、重複 URL とブラックリスト URL を除外した `merged.xml` を生成して GitHub Pages で公開するリポジトリです。

- サーバ不要（静的ファイルのみ）
- GitHub Actions で毎時更新
- GitHub Pages 公式アクション（artifact → deploy）で公開

## できること

- 複数フィードを取得して統合
- URL 完全一致で重複排除
- `blacklist.txt` の prefix 一致で除外
- 最新 50 件を RSS 2.0 (`public/merged.xml`) として出力
- タイトル先頭に `"[feed_name]"` を付与

## ファイル構成

- `feeds.yml`: フィード一覧（`name`, `url`）
- `blacklist.txt`: 除外URL prefix一覧（1行1ルール）
- `scripts/build_feed.rb`: 統合RSS生成スクリプト
- `public/merged.xml`: 生成される統合RSS
- `public/index.html`: Pages 用案内ページ
- `.github/workflows/build-and-deploy.yml`: 毎時実行 + Pages デプロイ

## 必要環境

- Ruby `4.0.1` 以上
- Bundler

## セットアップ

```bash
bundle install
```

## ローカル実行

```bash
bundle exec ruby scripts/build_feed.rb
```

実行後に以下が生成・更新されます。

- `public/merged.xml`

## テスト

テストコードは `test/` ディレクトリにあります。

個別実行:

```bash
ruby test/feed_test.rb
ruby test/fusion_rss_test.rb
ruby test/stats_test.rb
```

一括実行（シェル展開を使う例）:

```bash
ruby test/*_test.rb
```

## 設定方法

### `feeds.yml`

```yaml
feeds:
  - name: TechCrunch
    url: https://techcrunch.com/feed/
  - name: Example
    url: https://example.com/rss.xml
```

- `name`: 出力RSSのタイトル先頭に付く表示名（`[name]`）
- `url`: RSS/Atom フィードURL

### `blacklist.txt`

```txt
# 1行1ルール
https://qiita.com/some_user
https://example.com/ads/
```

- 空行と `#` コメントは無視
- 記事URLがいずれかの行で `start_with?` なら除外

## 出力仕様（MVP）

- 出力先: `public/merged.xml`
- 形式: RSS 2.0
- 件数: 最大 50 件（新しい順）
- `title`: `"[feed_name] {original_title}"`
- `link`: 元記事 URL
- `guid`: `link` と同じ URL
- `pubDate`: 元フィードの日時（無い場合は取得時刻で補完）

## GitHub Actions / GitHub Pages

### トリガー

- `push`（`main`）
- `schedule`（毎時 `0 * * * *`）
- `workflow_dispatch`（手動実行）

### 初回設定（重要）

`actions/configure-pages` を使うため、リポジトリで GitHub Pages を有効化してください。

1. GitHub リポジトリを開く
2. `Settings` → `Pages`
3. Source / Build and deployment を `GitHub Actions` にする

その後、workflow を再実行すると Pages デプロイが通ります。

## 公開URL

- サイト: `https://<USER>.github.io/<REPO>/`
- RSS: `https://<USER>.github.io/<REPO>/merged.xml`

このリポジトリ（`ledsun/rss-fusion`）の例:

- `https://ledsun.github.io/rss-fusion/`
- `https://ledsun.github.io/rss-fusion/merged.xml`

## トラブルシュート

### `cannot load such file -- rss`

Ruby 4 系では `rss` が別gem扱いの環境があるため、`Gemfile` に `gem "rss"` を追加済みです。`bundle install` 後に `bundle exec` で実行してください。

### 一部フィード取得に失敗する

仕様です。フィード単位の失敗はログ出力のみで継続し、取得できたフィードだけで `merged.xml` を生成します。

### Pages デプロイで `Get Pages site failed` / `Not Found`

Pages 未有効化が原因です。`Settings > Pages` で `GitHub Actions` を有効化してから再実行してください。

## ライセンス

MIT License（`LICENSE` を参照）
