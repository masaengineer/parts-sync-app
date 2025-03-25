# サービス概要
[![Image from Gyazo](https://i.gyazo.com/3a721fbb896e886a8c4ef51df114f372.jpg)](https://gyazo.com/3a721fbb896e886a8c4ef51df114f372)

**「Parts Sync」** は、越境EC販売者の管理会計をサポートするSaaS です。  
散らばったデータを少ない工数で一元管理でき、タイムリーな意思決定による売上向上を支援します。

# Why - なぜこのツールを開発するのか -
私は個人事業主として、6年間輸出EC販売に従事しましたが、ニッチな需要に対してのSaaSは行き届いておらず、  
非効率な労働集約型のビジネスモデルのままでは、自身の時間や体力のリソースの限界が業績の上限の要因となっていました。  

特に、商品単位の利益管理をして意思決定に必要な情報をなるべく早く集計することは、重要かつ緊急性も高い日次業務でしたが、
複数のスプレッドシートを関数で突合して情報を集約する方法は、事業拡大のフェーズでは煩雑になってしまい現実的ではありませんでした。

そこで、「もっとこんなツールがあればいいのに...」を形にしたのが「Parts Sync」です。  
日次作業の業務効率化をすることで事業者のリソースを増やし、迅速な意思決定をサポートすることで販売機会の向上を支援します。

今回はカーパーツを輸出販売している知人が、同じような課題を感じていることを知り、  
企画の段階から要求をヒアリングし、開発を進めました。


# How - どのように課題解決するか -

### ターゲティング

- **ペルソナ**：年商 3,000 万円〜数億円規模の越境EC 事業者
- **ユーザーが抱える課題**：
  - 日々変動する要因（仕入価格、為替、競合他社等）に対応し、競争力のある適正価格で販売するためには、商品単位の原価管理が必須である
  - 現状は、仕入代金、各プラットフォームの手数料、国内外の送料、各種外注費、為替情報などが複数のスプレッドシートで分散管理されている
  - データ更新の漏れや整合性の欠如が頻発してしまっており、月平均で 30〜50時間の工数がかかっている
- **解決策**：
  - 最適化されたデータベースを導入し、商品代金、手数料、送料、外注費などの情報を一元管理する
  - Webアプリで提供し、直感的で複雑性を排除したUIとすることで容易にスタッフ間で情報共有することが可能
  - 月次の集計作業にかかる工数を大幅に削減し、年間100万円規模のコストカット*を実現
 （※時間単価3千円、月25時間削減の場合の試算）

## 業界特化型の機能設計

- 海外販売プラットフォームeBayとのAPI連携対応し、1時間ごとの自動注文取り込み機能を実装
- 国際取引にまつわる多通貨（USD, EUR, GBP, AUD）へ対応


## 新規ユーザーの獲得方法
MVP リリース：複数のテストユーザーによる検証と改善
本リリース：カーパーツ業界のコミュニティを通じたマーケティング、既存ユーザーによる口コミ紹介  

# What - 何を提供するのか - 

### MVP リリース

- 売上レポート
- ユーザー登録
- 検索機能
- ページネーション
- CSV 取り込み

### 本リリース

- eBay APIによる受注情報の定期取得
- 月次レポート
- 表示件数の設定
- 項目の並び替え
- 多通貨対応
- 経費手動入力
- 取引詳細画面
- ダークモード
- オンラインツアーガイド
- ローディングアニメーション
- デモユーザー体験


# 使用技術

- **バックエンド**：Ruby 3.3.6 / Ruby on Rails 7.2.2.1
- **フロントエンド**：Hotwire（Turbo・stimulus）/ Tailwind CSS / DaisyUI
- **データベース**：PostgreSQL
- **インフラ**：Render
- **キャッシュ**：Redis
- **キューイング**：Sidekiq
- **CI/CD**：GitHub Actions
- **その他の技術**

# ER 図
[![Image from Gyazo](https://i.gyazo.com/219e7b0c7a3e8d4d4b58e573806667f9.png)](https://gyazo.com/219e7b0c7a3e8d4d4b58e573806667f9)
