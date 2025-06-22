namespace :ebay do
  desc "eBay注文と手数料の全同期"
  task sync_all: :environment do
    lockfile_path = Rails.root.join("tmp", "ebay_sync.lock")

    # 重複実行チェック
    if File.exist?(lockfile_path)
      Rails.logger.warn "⚠️  eBay同期が既に実行中です（PID: #{File.read(lockfile_path).strip}）"
      puts "⚠️  eBay同期が既に実行中です"
      exit
    end

    # ロックファイル作成
    File.write(lockfile_path, Process.pid)
    start_time = Time.current

    begin
      Rails.logger.info "🚀 eBay同期開始 - #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "🚀 eBay同期開始 - #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"

      # 注文同期実行
      sync_orders_with_retry

      # 手数料同期実行
      sync_fees_with_retry

      end_time = Time.current
      duration = ((end_time - start_time) / 1.minute).round(2)

      Rails.logger.info "✅ eBay同期完了 - 実行時間: #{duration}分"
      puts "✅ eBay同期完了 - 実行時間: #{duration}分"

    rescue => e
      Rails.logger.error "❌ eBay同期エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      puts "❌ eBay同期エラー: #{e.message}"
      raise
    ensure
      # ロックファイル削除
      File.delete(lockfile_path) if File.exist?(lockfile_path)
    end
  end

  desc "eBay注文同期のみ"
  task sync_orders: :environment do
    sync_orders_with_retry
  end

  desc "eBay手数料同期のみ"
  task sync_fees: :environment do
    sync_fees_with_retry
  end

  private

  def sync_orders_with_retry
    Rails.logger.info "=== eBay注文同期開始 ==="
    puts "=== eBay注文同期開始 ==="

    retry_count = 0
    max_retries = 3

    begin
      User.production_users.find_each do |user|
        begin
          Rails.logger.info "ユーザーID: #{user.id} の注文同期を開始"

          orders_data = Ebay::EbaySalesOrderClient.new.fetch_orders(user)
          Ebay::SalesOrderImporter.new(orders_data).import(user)

          Rails.logger.info "✅ ユーザーID: #{user.id} の注文同期完了"

        rescue Ebay::EbaySalesOrderClient::FulfillmentError => e
          Rails.logger.error "❌ ユーザーID: #{user.id} - eBay API エラー: #{e.message}"
          raise
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "❌ ユーザーID: #{user.id} - DB保存エラー: #{e.message}"
          raise
        rescue StandardError => e
          Rails.logger.error "❌ ユーザーID: #{user.id} - 予期せぬエラー: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          raise
        end
      end

      Rails.logger.info "✅ 全ユーザーのeBay注文同期完了"
      puts "✅ 全ユーザーのeBay注文同期完了"

    rescue => e
      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "⚠️  注文同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        puts "⚠️  注文同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        sleep 5
        retry
      else
        Rails.logger.error "❌ 注文同期が最大リトライ回数に達しました"
        puts "❌ 注文同期が最大リトライ回数に達しました"
        raise
      end
    end
  end

  def sync_fees_with_retry
    Rails.logger.info "🔄 eBay取引手数料同期開始"
    puts "🔄 eBay取引手数料同期開始"

    retry_count = 0
    max_retries = 3

    begin
      importer = Ebay::SellerFeeTransactionImporter.new
      log_output = importer.import(User.production_users)

      Rails.logger.info "📝 インポート詳細:\n#{log_output}"
      Rails.logger.info "✅ eBay取引手数料同期完了"
      puts "✅ eBay取引手数料同期完了"

    rescue Ebay::SellerFeeTransactionImporter::ImportError => e
      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        puts "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        sleep 5
        retry
      else
        Rails.logger.error "❌ 取引手数料インポートエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        puts "❌ 手数料同期が最大リトライ回数に達しました"
        raise
      end
    rescue ActiveRecord::RecordInvalid => e
      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        puts "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        sleep 5
        retry
      else
        Rails.logger.error "❌ DB保存エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        puts "❌ 手数料同期が最大リトライ回数に達しました"
        raise
      end
    rescue StandardError => e
      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        puts "⚠️  手数料同期リトライ #{retry_count}/#{max_retries} - 5秒後に再実行"
        sleep 5
        retry
      else
        Rails.logger.error "❌ 予期せぬエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        puts "❌ 手数料同期が最大リトライ回数に達しました"
        raise
      end
    end
  end
end
