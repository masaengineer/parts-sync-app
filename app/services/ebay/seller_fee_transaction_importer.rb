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

    # 取引データをインポート
    # @return [String] 処理結果
    def import
      transactions_data = @api_client.fetch_transactions

      begin
        process_transactions(transactions_data["transactions"])
      rescue StandardError => e
        raise ImportError, "取引データのインポートに失敗しました: #{e.message}"
      end

      "処理が完了しました"
    end

    private

    # 取引データを処理
    # @param transactions [Array] 取引データの配列
    def process_transactions(transactions)
      transactions.each do |transaction|
        order_number = find_order_number(transaction)

        next unless order_number

        order = Order.find_by(order_number: order_number)
        next unless order

        process_transaction_by_type(order, transaction)
      end
    end

    # 取引タイプに応じて適切なプロセッサークラスを使用
    # @param order [Order] 注文オブジェクト
    # @param transaction [Hash] 取引データ
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

    # 取引データから注文番号を取得
    # @param transaction [Hash] 取引データ
    # @return [String, nil] 注文番号
    def find_order_number(transaction)
      order_number = if transaction["transactionType"] == "NON_SALE_CHARGE"
        # references 配列から referenceType が ORDER_ID の要素を探す
        order_id_reference = transaction["references"]&.find { |ref| ref["referenceType"] == "ORDER_ID" }
        order_id_reference&.[]("referenceId")
      else
        # 通常の処理 (SALE, REFUND, SHIPPING_LABEL など)
        transaction["orderId"]
      end

      return nil if order_number.nil? || order_number == "0"

      order_number
    end
  end
end
