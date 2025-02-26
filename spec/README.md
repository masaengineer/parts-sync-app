# テスト戦略ガイド

このドキュメントでは、プロジェクトのテスト戦略について説明します。テストピラミッドの考え方に基づき、各レベルのテストの役割と実装ガイドラインを示します。

## テストピラミッド

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

## テストタグ

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

# Docker環境でテストを実行する場合は、docker_接頭辞のタスクを使用
bin/rails test:docker_run
bin/rails test:docker_fast
bin/rails test:docker_system
bin/rails test:docker_smoke
```

## CI 環境でのテスト実行

CI 環境では、以下の順序でテストを実行することを推奨します：

1. 単体テスト（高速なテスト）
2. 統合テスト
3. スモークテスト（基本的な E2E テスト）
4. 全ての E2E テスト

これにより、問題を早期に発見できます。

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
