class EbayTransactionFeesSyncJob < ApplicationJob
  queue_as :default

  retry_on Ebay::SellerFeeTransactionImporter::ImportError, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform
    Rails.logger.info "🔄 eBay取引手数料同期開始"

    # すべてのユーザーに対して処理を実行
    User.find_each do |user|
      begin
        Rails.logger.info "ユーザーID: #{user.id} の取引手数料同期を開始"

        # ユーザー情報を渡してインポーターを初期化
        importer = Ebay::SellerFeeTransactionImporter.new(user)
    log_output = importer.import

        # インポートの詳細ログを記録
        Rails.logger.info "📝 ユーザーID: #{user.id} - インポート詳細:\n#{log_output}"
        Rails.logger.info "✅ ユーザーID: #{user.id} の取引手数料同期完了"
  rescue Ebay::SellerFeeTransactionImporter::ImportError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - 取引手数料インポートエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise  # 再試行のために例外を再度発生
      rescue StandardError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - 予期せぬエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise  # 再試行のために例外を再度発生
      end
    end

    Rails.logger.info "✅ 全ユーザーのeBay取引手数料同期完了"
  rescue StandardError => e
    Rails.logger.error "❌ 全体的なエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise  # 再試行のために例外を再度発生
  end
end
