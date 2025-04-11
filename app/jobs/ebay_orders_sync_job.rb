class EbayOrdersSyncJob < ApplicationJob
  queue_as :default

  retry_on Ebay::EbaySalesOrderClient::FulfillmentError, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform
    Rails.logger.info "=== eBay注文同期開始 ==="

    User.production_users.find_each do |user|
      begin
        Rails.logger.info "ユーザーID: #{user.id} の注文同期を開始"

        orders_data = Ebay::EbaySalesOrderClient.new.fetch_orders(user)

        Ebay::SalesOrderImporter.new(orders_data).import(user)

        Rails.logger.info "✅ ユーザーID: #{user.id} の注文同期完了"
      rescue Ebay::EbaySalesOrderClient::FulfillmentError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - eBay API エラー: #{e.message}"
        Rails.logger.error e.backtrace.joinq("\n")
        raise
      rescue StandardError => e
        Rails.logger.error "❌ ユーザーID: #{user.id} - 予期せぬエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise
      end
    end

    Rails.logger.info "✅ 全ユーザーのeBay注文同期完了"
  end
end
