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
      transactions.each do |transaction|
        order_number = find_order_number(transaction)

        next unless order_number

        order = Order.joins(:user).where(users: { id: users.pluck(:id) }).find_by(order_number: order_number)
        next unless order

        process_transaction_by_type(order, transaction)
      end
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
