require_relative "transactions/base_transaction_processor"
require_relative "transactions/sale_transaction_processor"
require_relative "transactions/shipping_label_transaction_processor"
require_relative "transactions/non_sale_charge_transaction_processor"
require_relative "transactions/refund_transaction_processor"

module Ebay
  class SellerFeeTransactionImporter
    class ImportError < StandardError; end

    def initialize(api_client = EbayFinanceClient.new)
      @api_client = api_client
    end

    def import(users = User.all)
      begin
        transactions_data = @api_client.fetch_transactions
        process_transactions(transactions_data["transactions"], users)
      rescue StandardError => e
        raise ImportError, "取引データのインポートに失敗しました: #{e.message}"
      end

      "処理が完了しました"
    end

    private

    def process_transactions(transactions, users)
      Rails.logger.info "📊 取引処理開始 - 総件数: #{transactions.size}"

      # 事前に重複取引をフィルタリング
      processed_transaction_ids = PaymentFee.joins(:order)
        .where(orders: { user_id: users.pluck(:id) })
        .pluck(:transaction_id)
        .to_set

      Rails.logger.info "📋 既存取引件数: #{processed_transaction_ids.size}"

      filtered_transactions = transactions.reject do |transaction|
        processed_transaction_ids.include?(transaction["transactionId"])
      end

      Rails.logger.info "🔄 処理対象取引件数: #{filtered_transactions.size}"

      # 早期終了チェック
      if filtered_transactions.size == 0
        Rails.logger.info "⚡ 新規取引なし - 処理をスキップ"
        return
      end

      duplicate_ratio = (transactions.size - filtered_transactions.size) / transactions.size.to_f
      if duplicate_ratio > 0.9
        Rails.logger.warn "⚠️  重複率が高い (#{(duplicate_ratio * 100).round(1)}%) - 最新データのみ処理"
        filtered_transactions = filtered_transactions.first(500)
      end

      # バッチ処理
      batch_size = 100
      filtered_transactions.each_slice(batch_size).with_index do |batch, batch_index|
        Rails.logger.info "📦 バッチ #{batch_index + 1}/#{(filtered_transactions.size / batch_size.to_f).ceil} 処理中 (#{batch.size}件)"

        batch.each do |transaction|
          order_number = find_order_number(transaction)
          next unless order_number

          order = Order.joins(:user).where(users: { id: users.pluck(:id) }).find_by(order_number: order_number)
          next unless order

          process_transaction_by_type(order, transaction)
        end

        Rails.logger.info "✅ バッチ #{batch_index + 1} 完了"
      end

      Rails.logger.info "�� 全取引処理完了"
    end

    def process_transaction_by_type(order, transaction)
      processor_class = case transaction["transactionType"]
      when "SALE"
          Ebay::Transactions::SaleTransactionProcessor
      when "SHIPPING_LABEL"
          Ebay::Transactions::ShippingLabelTransactionProcessor
      when "NON_SALE_CHARGE"
          Ebay::Transactions::NonSaleChargeTransactionProcessor
      when "REFUND"
          Ebay::Transactions::RefundTransactionProcessor
      else
          Rails.logger.debug "Unsupported transaction type: #{transaction['transactionType']}"
          return
      end

      processor_class.new(order, transaction).process
    end

    def find_order_number(transaction)
      order_number = if transaction["transactionType"] == "NON_SALE_CHARGE"
        order_id_reference = transaction["references"]&.find { |ref| ref["referenceType"] == "ORDER_ID" }
        order_id_reference&.[]("referenceId")
      else
        transaction["orderId"]
      end

      return nil if order_number.nil? || order_number == "0"

      order_number
    end
  end
end
