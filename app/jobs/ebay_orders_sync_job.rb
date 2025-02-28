class EbayOrdersSyncJob < ApplicationJob
  queue_as :default

  # エラー時の再試行設定
  retry_on Ebay::EbaySalesOrderClient::FulfillmentError, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform
    Rails.logger.info "=== eBay注文同期開始 ==="

    # すべてのユーザーに対して処理を実行
    User.find_each do |user|
      begin
        Rails.logger.info "ユーザーID: #{user.id} の注文同期を開始"

        # eBay APIからデータを取得するサービス
        orders_data = Ebay::EbaySalesOrderClient.new.fetch_orders(user)

        # 取得したデータをインポート
        Ebay::SalesOrderImporter.new(orders_data).import(user)

        Rails.logger.info "✅ ユーザーID: #{user.id} の注文同期完了"
      rescue Ebay::EbaySalesOrderClient::FulfillmentError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - eBay API エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise  # 再試行のために例外を再度発生
      rescue StandardError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - 予期せぬエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise  # 再試行のために例外を再度発生
      end
    end

    Rails.logger.info "✅ 全ユーザーのeBay注文同期完了"
  end
end
