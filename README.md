# 📊 Parts Sync | 越境 EC 販売者のための管理会計 SaaS

[![Image from Gyazo](https://i.gyazo.com/3a721fbb896e886a8c4ef51df114f372.jpg)](https://gyazo.com/3a721fbb896e886a8c4ef51df114f372)

**「Parts Sync」** は、越境 EC 販売者の管理会計をサポートする SaaS です。<br>
散らばったデータを少ない工数で一元管理でき、タイムリーな意思決定による売上向上を支援します。
<br><br><br>

## Why - なぜこのツールを開発するのか

### 🔍 個人事業時代の課題

輸出 EC 販売に 6 年間従事した経験から、ニッチな市場には SaaS が行き届いていないこと実感していました。労働集約型ビジネスモデルでは、個人の時間や体力のリソース制限が業績の上限になってしまいます。

### 📊 データ管理の非効率性

販売戦略の意思決定に必要な商品単位の利益の集計は日次業務として重要ですが、複数のスプレッドシートに分散管理された情報を関数で突合する方法は事業拡大フェーズでは煩雑で非現実的でした。

### 💡 「Parts Sync」の企画

「もっとこんなツールがあればいいのに...」という思いから生まれた「Parts Sync」は、日次作業の業務効率化で事業者のリソースを増やし、迅速な意思決定をサポートして販売機会の向上を支援します。

### 👥 ユーザー中心の開発アプローチ

カーパーツを輸出販売する知人の課題に共感し、企画段階から要求をヒアリングしながら仕様を固めました。ユーザーが要望する機能をそのまま開発するのではなく、「ユーザーが本質的に望んでいる機能は何か」を意識し、開発コストと要求の充足度を比較検討しながら開発を進めました。
<br><br><br>

## How - どのように課題解決するか

### 🎯 ペルソナ

年商 3,000 万円〜数億円規模の越境 EC 事業者<br>

#### ユーザーが抱える課題：

- 日々変動する要因（仕入価格、為替、競合他社等）に対応し、競争力のある適正価格で販売するためには、商品単位の原価管理が必須である
- 現状は、仕入代金、各プラットフォームの手数料、国内外の送料、各種外注費、為替情報などが**複数のスプレッドシートで分散管理されている**
- データ更新の漏れや整合性の欠如が頻発してしまっており、**月平均で 30〜50 時間の工数**がかかっている

#### 解決策：

- 最適化されたデータベースを導入し、商品代金、手数料、送料、外注費などの**情報を一元管理**する
- Web アプリで提供し、直感的で複雑性を排除した UI とすることで容易にスタッフ間で情報共有することが可能
- 月次の集計作業にかかる工数を大幅に削減し、**年間 100 万円規模のコストカット**\*を実現<br>（※時間単価 3 千円、月 30 時間削減の場合の試算）

### 🔧 業界特化型の機能設計

- 海外販売プラットフォーム eBay との API 連携対応し、**1 時間ごとの自動注文取り込み機能を実装**
- 国際取引にまつわる多通貨（USD, CAD, EUR, GBP, AUD）へ対応

### 🚀 新規ユーザーの獲得方法

- **MVP リリース：** 複数のテストユーザーによる検証と改善
- **本リリース：** カーパーツ販売者のコミュニティを通じた営業、既存ユーザーによる口コミ紹介
<br><br><br>

## What - 何を具体として提供するのか <br>

### 主な機能

| カテゴリ         | 機能                                                                                                                                               |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **売上レポート** | ・eBay API 連携による受注情報自動取得<br>・CSV 取り込み<br>・販売商品一覧と詳細表示<br>・検索/フィルタリング機能<br>・価格調整メモ<br>・多通貨対応 |
| **月次レポート** | ・年間業績グラフ表示<br>・経費入力/管理                                                                                                            |
| **全般**         | ・ユーザー登録/認証<br>・ダークモード<br>・オンラインツアーガイド<br>・ローディングアニメーション<br>・デモユーザー体験                            |

### 主要機能のデモ

<table>
<tr>
<td width="50%">

#### 📥 販売情報取り込み機能

<details>
<summary>詳細（クリックして表示）</summary>
CSV 形式のインポートでは委託先から入手した外注費を DB へ保存します。<br>また、基本情報はプラットフォームの API 経由で自動的に更新されます。Sidekiq+Redis を用いて 1 時間ごとの定期実行を実現しました。
</details>

[![Image from Gyazo](https://i.gyazo.com/5fb5078493a916a67b9e1dcd23478287.gif)](https://gyazo.com/5fb5078493a916a67b9e1dcd23478287)

</td>
<td width="50%">

#### 🔍 フィルタリング機能

<details>
<summary>詳細（クリックして表示）</summary>
Ransack を利用した検索機能です。販売データを日付、注文番号、追跡番号、SKU コードでマルチ検索することができます。<br>アイコンやプレースホルダーを利用することで、情報量を最小限にしつつ、直感的な UI を実現しています。
</details>

[![Image from Gyazo](https://i.gyazo.com/c39aaff5e467c1b1c1f93d1f86959412.gif)](https://gyazo.com/c39aaff5e467c1b1c1f93d1f86959412)

</td>
</tr>
<tr>
<td width="50%">

#### 📝 オーダー詳細 & 価格調整メモ機能

<details>
<summary>詳細（クリックして表示）</summary>
Turbo Frames/Streams & Stimulus を利用することで商品一覧画面からページ遷移せずにモーダル画面表示をしたり、販売金額調整のメモを登録できます。<br>また、HTMLのダイアログ機能を使ってESC キーや、枠外のクリックでモーダルを閉じることができ、再レンダリング不要で青色の価格調整日バッジが一覧画面に記載されます。
</details>

[![Image from Gyazo](https://i.gyazo.com/86e1fcede5b99059502eb51146b6caf3.gif)](https://gyazo.com/86e1fcede5b99059502eb51146b6caf3)

</td>
<td width="50%">

#### 💰 経費入力機能

<details>
<summary>詳細（クリックして表示）</summary>
商品別の利益計算には含めたくない経費で、かつ月次レポートには含めたい項目はこちらで手動入力することができます。<br>一部の委託費用については、CSVインポート時に自動的にこちらの機能へ登録されます。
</details>

[![Image from Gyazo](https://i.gyazo.com/e428dcbca255851103774bf2cc259800.gif)](https://gyazo.com/e428dcbca255851103774bf2cc259800)

</td>
</tr>
<tr>
<td width="50%">

#### 🎯 オンラインツアーガイド機能

<details>
<summary>詳細（クリックして表示）</summary>
Tour.jsのJavaScriptライブラリを利用することで、初めてログインするユーザーに対して視覚的なオンライツアーを提供しています。<br>初回の認知負荷を下げることでユーザー体験を向上させる狙いで導入しました。
</details>

[![Image from Gyazo](https://i.gyazo.com/a2b15bd487d7a6200caee2719c018a15.gif)](https://gyazo.com/a2b15bd487d7a6200caee2719c018a15)

</td>
<td width="50%">
</td>
</tr>
</table>
<br>

## 使用技術

| カテゴリ           | 技術                                               |
| ------------------ | -------------------------------------------------- |
| **バックエンド**   | Ruby 3.3.6 / Ruby on Rails 7.2.2.1                 |
| **フロントエンド** | Hotwire（Turbo・stimulus）/ Tailwind CSS / DaisyUI |
| **データベース**   | PostgreSQL                                         |
| **インフラ**       | Render                                             |
| **キャッシュ**     | Redis                                              |
| **キューイング**   | Sidekiq / Sidekiq-scheduler                        |
| **テスト**         | RSpec / FactoryBot / Capybara / SimpleCov          |
| **CI/CD**          | GitHub Actions                                     |
| **認証・認可**     | Devise / OmniAuth (Google OAuth2)                  |
| **API 通信**       | Faraday / OAuth2                                   |
| **UI/UX 機能**     | Kaminari（ページネーション）/ Ransack（検索機能）  |
| **国際化**         | Rails-i18n                                         |
| **コンテナ化**     | Docker / Docker Compose                            |
| **セキュリティ**   | Brakeman / Bundler-audit                           |
| **開発ツール**     | Rubocop / Overcommit                               |

<br>

## ER 図

[![Image from Gyazo](https://i.gyazo.com/219e7b0c7a3e8d4d4b58e573806667f9.png)](https://gyazo.com/219e7b0c7a3e8d4d4b58e573806667f9)
