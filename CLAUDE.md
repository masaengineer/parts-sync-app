# Cronジョブ実装に関する設定情報

## 概要
SidekiqからCronジョブ方式に変更してインフラコストを削減（$30/月 → $14/月）

## 実装内容

### 1. rake task
- **ファイル**: `lib/tasks/ebay_sync.rake`
- **主要タスク**:
  - `rake ebay:sync_all` - 注文と手数料の全同期
  - `rake ebay:sync_orders` - 注文同期のみ
  - `rake ebay:sync_fees` - 手数料同期のみ

### 2. 手動実行機能
- **URL**: `/admin/sync`
- **機能**: ログインユーザーが手動で同期を実行可能
- **ファイル**: 
  - `app/controllers/admin/sync_controller.rb`
  - `app/views/admin/sync/show.html.erb`

### 3. Render Cron Jobs設定（要設定）
```
# 1日3回実行（朝6時、昼14時、夜20時）
スケジュール1: 0 6 * * *   (毎日朝6時)
スケジュール2: 0 14 * * *  (毎日昼14時)  
スケジュール3: 0 20 * * *  (毎日夜20時)
コマンド: bundle exec rake ebay:sync_all
インスタンス: Starter ($1/月)
```

## 変更されたファイル
- `config/application.rb` - ActiveJobをinlineに変更
- `config/sidekiq.yml` → `config/sidekiq.yml.backup` (バックアップ)
- `config/initializers/sidekiq.rb` → `config/initializers/sidekiq.rb.backup` (バックアップ)

## 元に戻す場合
1. バックアップファイルを元に戻す
2. `config/application.rb`のqueue_adapterを`:sidekiq`に戻す
3. Render上でSidekiq/Redisサービスを再起動

## テスト実行方法
```bash
# 開発環境でのテスト
bundle exec rake ebay:sync_all

# 本番環境でのテスト（Render上で）
# /admin/sync にアクセスして手動実行
```

## 監視すべきポイント
- 実行時間（通常1-5分）
- ログ出力（`log/production.log`）
- ロックファイルの残存チェック（`tmp/ebay_sync.lock`）