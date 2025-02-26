# テスト戦略と実行ガイド

このドキュメントでは、プロジェクトのテスト戦略と実行方法について説明します。テストピラミッドの考え方に基づき、各レベルのテストの役割と実装ガイドラインを示します。

## 目次

1. [テストピラミッドの概念](#テストピラミッドの概念)
2. [テストの種類と役割](#テストの種類と役割)
3. [テスト実装のガイドライン](#テスト実装のガイドライン)
4. [テストタグとフィルタリング](#テストタグとフィルタリング)
5. [テスト実行コマンド](#テスト実行コマンド)
6. [Docker 環境でのテスト実行](#Docker環境でのテスト実行)
7. [CI 環境でのテスト実行](#CI環境でのテスト実行)
8. [テスト作成時の注意点](#テスト作成時の注意点)
9. [現在実装されているテストの概要](#現在実装されているテストの概要)
10. [今後実装予定のテスト](#今後実装予定のテスト)
11. [トラブルシューティング](#トラブルシューティング)

## テストピラミッドの概念

テストピラミッドは以下の 3 つの層から構成されます：

```
    /\
   /  \
  /E2E \
 /     \
/統合テスト\
/-----------\
/  単体テスト  \
```

1. **単体テスト（底辺）**: モデルテスト、サービステストなど
2. **統合テスト（中間）**: リクエストテスト、コントローラーテストなど
3. **E2E テスト（頂点）**: システムテスト（ブラウザを使用した UI 検証）

テストピラミッドの考え方では、下層のテストの数が多く、上層のテストの数が少ないことが理想的です。これにより、テスト実行の速度を保ちながら、十分なカバレッジを確保できます。

## テストの種類と役割

### 単体テスト

- **対象**: モデル、サービス、ヘルパーなどの個別のコンポーネント
- **目的**: 各コンポーネントが正しく動作すること、バリデーションやビジネスロジックが適切に機能することを確認する
- **実装**: `spec/models/`, `spec/services/` などに配置
- **実行速度**: 非常に速い

### 統合テスト

- **対象**: コントローラー、複数のコンポーネントの連携
- **目的**: リクエスト処理の流れ、コントローラーのアクション、フラッシュメッセージなどが適切に機能することを確認する
- **実装**: `spec/requests/` に配置
- **実行速度**: やや遅い

### E2E テスト

- **対象**: ユーザーの視点からの一連の操作、UI の挙動
- **目的**: エンドユーザーの視点で機能が正しく動作することを確認する
- **実装**: `spec/system/` に配置
- **実行速度**: 非常に遅い（特に JavaScript を使用するテスト）

## テスト実装のガイドライン

### 単体テスト

- 以下の観点でテストを作成する：
  - バリデーションの確認
  - スコープやクエリメソッドの確認
  - インスタンスメソッドの動作確認
  - エッジケースや境界値の確認

```ruby
# 例：モデルテスト
RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
  end

  describe "scopes" do
    it "active returns only active users" do
      # ...
    end
  end
end
```

### 統合テスト

- 以下の観点でテストを作成する：
  - レスポンスコードの確認
  - リダイレクト先の確認
  - フラッシュメッセージの確認
  - データの変更が正しく反映されるか
  - エラー処理（例外ケース）の確認

```ruby
# 例：リクエストテスト
RSpec.describe "Users", type: :request do
  describe "POST /users" do
    it "creates a new user with valid params" do
      expect {
        post users_path, params: { user: valid_attributes }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(user_path(User.last))
      expect(flash[:notice]).to be_present
    end
  end
end
```

### E2E テスト

- 重要なユーザーフローのみを選択的にテストする
- 以下の観点でテストを作成する：
  - 基本的なナビゲーション
  - フォーム入力と送信
  - JavaScript によるインタラクション
  - 主要な機能の一連の操作

```ruby
# 例：システムテスト
RSpec.describe "ユーザー登録", type: :system do
  it "ユーザーが新規登録できること", js: true do
    visit new_user_registration_path

    fill_in "名前", with: "山田太郎"
    fill_in "メールアドレス", with: "test@example.com"
    fill_in "パスワード", with: "password"
    fill_in "パスワード（確認）", with: "password"

    click_button "登録する"

    expect(page).to have_content("アカウント登録が完了しました")
  end
end
```

## テストタグとフィルタリング

以下のタグを使用して、テストの実行をコントロールできます：

- `js: true`: JavaScript を使用するテスト
- `slow: true`: 実行時間の長いテスト
- `group: :smoke`: 基本的な操作確認（スモークテスト）

```ruby
# タグの使用例
it "複雑な操作を行うテスト", js: true, slow: true do
  # ...
end

describe "基本的な確認", group: :smoke do
  # ...
end
```

## テスト実行コマンド

テスト実行には以下の Rake タスクが利用できます：

```bash
# 全てのテストを実行
bin/rails test:all

# 高速テストのみを実行（:slowと:jsタグなし）
bin/rails test:fast

# モデルテストのみを実行
bin/rails test:models

# 統合テストのみを実行
bin/rails test:requests

# E2Eテストのみを実行
bin/rails test:system

# 基本的な操作のスモークテストのみを実行
bin/rails test:smoke
```

## Docker 環境でのテスト実行

テスト用の Docker 環境が`compose.test.yml`と`Dockerfile.test`で定義されています。この環境は以下の特徴を持ちます：

- 実環境と分離されたデータベース
- テスト専用の Redis インスタンス
- Chromium ブラウザによるヘッドレステスト
- 環境変数の適切な設定

### Docker 環境でのテスト実行コマンド

```bash
# テスト環境の初期化
docker compose -f compose.test.yml run --rm test bundle exec rails db:create db:schema:load RAILS_ENV=test

# 全てのテストを実行
bin/rails test:docker_run

# 高速テストのみを実行
bin/rails test:docker_fast

# E2Eテストのみを実行
bin/rails test:docker_system

# スモークテストのみを実行
bin/rails test:docker_smoke
```

### 特定のテストのみを実行する場合

```bash
# 特定の機能のテストのみ実行
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system/products

# 個別のテストファイルを実行
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system/products/crud_spec.rb

# 見やすいフォーマットでテスト結果を表示
docker compose -f compose.test.yml run --rm test bundle exec rspec spec/system --format documentation
```

### Docker 環境でのテスト注意事項

1. **JavaScript テスト**

   - `js: true`指定のテストは、Capybara の設定通りに Chromium を使用して実行されます。
   - 一部の JavaScript テストは設定が必要なため、`:slow`タグを付けて一般開発者は実行しないように設定しています。

2. **テストデータについて**

   - テストは`test`環境で実行され、データベースはリセットされるので安全に実行できます。

3. **テスト終了後のクリーンアップ**
   ```bash
   docker compose -f compose.test.yml down -v
   ```

## CI 環境でのテスト実行

CI 環境では、以下の順序でテストを実行することを推奨します：

1. 単体テスト（高速なテスト）
2. 統合テスト
3. スモークテスト（基本的な E2E テスト）
4. 全ての E2E テスト

これにより、問題を早期に発見できます。GitHub Actions のワークフローが`.github/workflows/test.yml`に定義されています。

## テスト作成時の注意点

1. **モックとスタブの適切な使用**

   - 外部サービスや遅い処理はモック/スタブを使用する
   - しかし過剰な使用は避け、実際の挙動とかけ離れないようにする

2. **境界値・エッジケースのテスト**

   - 正常系だけでなく、エラーケースもテストする
   - 境界値（最小値、最大値）のテストを含める

3. **テストデータの管理**

   - FactoryBot を活用して必要最小限のデータを作成する
   - テスト間の依存を避ける（各テストは独立して実行できるようにする）

4. **テストの保守性**
   - テスト自体も保守が必要なコードという認識を持つ
   - テストコードもリファクタリングの対象とする

## 現在実装されているテストの概要

### ユーザー認証機能

- ユーザー登録
- ログイン/ログアウト
- プロフィール編集

### 商品管理機能

- 一覧表示（新規登録、編集、削除は今後実装予定）

### 検索機能

- 商品検索（名前・コード）
- 注文検索（注文番号・追跡番号）

### データインポート機能

- Wisewill 委託分シートインポート
- CPaSS 委託分シートインポート

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

## トラブルシューティング

### テストが失敗する場合

1. **スクリーンショットとログを確認**

   - 失敗したテストのスクリーンショットは`tmp/screenshots`ディレクトリに保存されます
   - ブラウザのコンソールログを確認するには`log/test.log`を参照してください

2. **Docker 環境をリビルド**

   ```bash
   docker compose -f compose.test.yml build --no-cache
   ```

3. **テストデータベースをリセット**

   ```bash
   docker compose -f compose.test.yml run --rm test bundle exec rails db:reset RAILS_ENV=test
   ```

4. **システムテストの安定性向上**

   - `spec/support/system_test_helpers.rb`に定義されているヘルパーメソッドを活用して、待機処理を適切に実装してください

   ```ruby
   # 例：ページの読み込み完了を待つ
   wait_for_page_load

   # 例：特定の要素が表示されるまで待つ
   wait_for_selector('.my-element')
   ```
