class EbayTransactionFeesSyncJob < ApplicationJob
  queue_as :default

  retry_on Ebay::SellerFeeTransactionImporter::ImportError, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform
    Rails.logger.info "🔄 eBay取引手数料同期開始"

    # デモユーザーを除外して、本番ユーザーのみを対象に処理実行
    importer = Ebay::SellerFeeTransactionImporter.new
    log_output = importer.import(User.production_users)

    # インポートの詳細ログを記録
    Rails.logger.info "📝 インポート詳細:\n#{log_output}"
    Rails.logger.info "✅ eBay取引手数料同期完了"
  rescue Ebay::SellerFeeTransactionImporter::ImportError => e
    Rails.logger.error "❌ 取引手数料インポートエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise  # 再試行のために例外を再度発生
  rescue StandardError => e
    Rails.logger.error "❌ 予期せぬエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise  # 再試行のために例外を再度発生
  end
end
