# システムスペック実行ガイド

このドキュメントでは、Docker 環境での効率的なシステムスペックの実行方法について説明します。

## 実行環境

テスト用の Docker コンテナ環境が`compose.test.yml`と`Dockerfile.test`で定義されています。これにより、以下の特徴を持つ専用のテスト環境が構築されます：

- 実環境と分離されたデータベース
- テスト専用の Redis インスタンス
- Chromium ブラウザによるヘッドレステスト
- 環境変数の適切な設定

## 基本的なテスト実行コマンド

### テスト環境の初期化

初めてテスト環境を使う場合や、データベーススキーマを再構築する場合：

```bash
docker compose -f compose.test.yml run --rm test bundle exec rails db:create db:schema:load RAILS_ENV=test
```

### 全てのシステムスペックを実行

```bash
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system
```

### 特定の機能のテストのみ実行

```bash
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system/products
```

### 個別のテストファイルを実行

```bash
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system/products/crud_spec.rb
```

### 見やすいフォーマットでテスト結果を表示

```bash
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system --format documentation
```

## 注意事項

1. **JavaScript テスト**

   - JavaScript を使用するテスト（`js: true`指定のもの）は、Capybara の設定通りに Chromium を使用して実行されます。
   - 一部の JavaScript テストは現在 Docker 環境で実行するための追加設定が必要なため、一時的にスキップされています。

2. **テストデータについて**

   - テストは`test`環境で実行され、データベースは実行のたびにリセットされるので、安全に何度でも実行できます。

3. **テスト終了後のクリーンアップ**
   - テスト完了後は以下のコマンドでコンテナとボリュームを削除することをお勧めします：
     ```bash
     docker compose -f compose.test.yml down -v
     ```

## 現在実装されているシステムスペック

1. **ユーザー認証機能**

   - ユーザー登録
   - ログイン/ログアウト
   - プロフィール編集

2. **商品管理機能**

   - 一覧表示（新規登録、編集、削除は今後実装予定）

3. **検索機能**

   - 商品検索（名前・コード）
   - 注文検索（注文番号・追跡番号）

## 今後実装予定のテスト

1. **CSV インポート機能**

   - 正常な CSV ファイルのインポート
   - 不正なフォーマットの CSV ファイル処理
   - 重複データの処理

2. **カテゴリ管理機能**

   - カテゴリの一覧表示
   - カテゴリの新規作成
   - カテゴリの編集と削除

3. **売上データ分析機能**
   - 月次売上レポート
   - 商品別売上分析
   - カスタムレポート生成

## 実施結果

2024 年 7 月 XX 日時点の実行結果：

- 全テスト数: 9
- 成功: 9
- 失敗: 0
- 保留: 7（JavaScript 関連テストや未実装機能のテスト）

## トラブルシューティング

### テストが失敗する場合

1. **スクリーンショットとログを確認**

   - 失敗したテストのスクリーンショットは`tmp/screenshots`ディレクトリに保存されます
   - ブラウザのコンソールログを確認するには`log/test.log`を参照してください

2. **Docker コンテナをリビルド**

   ```bash
   docker compose -f compose.test.yml build --no-cache
   ```

3. **テストデータベースをリセット**
   ```bash
   docker compose -f compose.test.yml run --rm test bundle exec rails db:reset RAILS_ENV=test
   ```
