# 通貨管理機能の実装手順

## 概要

このドキュメントでは、通貨管理機能の実装手順について説明します。この変更により、アプリケーション内のさまざまな金額フィールドに通貨情報を関連付けることができるようになります。

## 実装内容

1. **Currencyテーブルの作成**
   - 通貨コード、名前、記号などの情報を持つテーブル
   - 主要な通貨（USD, JPY, EUR, GBP, CAD, AUD）の初期データを提供

2. **enumによる通貨コード管理**
   - Currencyモデルで通貨コードをenumとして定義
   - 直感的な通貨指定が可能（例: `Currency.usd.first`）

3. **既存テーブルへの通貨参照の追加**
   - `orders`, `sales`, `order_lines`, `payment_fees`, `shipments`テーブルに`currency_id`カラムを追加
   - 各モデルに`belongs_to :currency`関連を追加
   - 共通機能を`HasCurrency`モジュールとして実装

## 実行手順

### マイグレーションの実行

以下のコマンドを実行して、データベースを更新します。

```bash
# マイグレーションの実行
docker compose run --rm web rails db:migrate
```

### 通貨初期データの投入

以下のコマンドを実行して、通貨の初期データを投入します。

```bash
# シードの実行
docker compose run --rm web rails runner db/seeds/currencies.rb
```

## 使用方法

### 通貨の参照と指定

```ruby
# 通貨を取得する方法
usd_currency = Currency.find_by(code: 'USD')
# またはenumを使用
usd_currency = Currency.code_usd.first

# 注文に通貨を関連付ける
order = Order.find(1)
order.update(currency: usd_currency)
```

### 通貨でのフィルタリング

```ruby
# 米ドルでの注文を取得
usd_orders = Order.with_usd
# または
usd_orders = Order.with_currency('USD')
```

### 金額表示

```ruby
# 注文の合計金額を通貨記号付きで表示
order = Order.find(1)
formatted_total = order.formatted_amount(:total_amount)
# 例: "$123.45"
```

### 通貨設定ヘルパーメソッド

```ruby
# 注文の通貨を設定
order = Order.find(1)
order.set_currency('JPY')
```

## 注意点

- 既存のデータに対しては、通貨情報が設定されていないため、必要に応じて更新する必要があります。
- APIからのデータインポート時には、`Currency.find_or_create_by_code`メソッドを使用して、通貨情報も適切に保存するようにインポートロジックを修正する必要があります。
