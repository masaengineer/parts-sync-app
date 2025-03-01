module Ebay
  module Transactions
    # 配送ラベル取引処理クラス
    class ShippingLabelTransactionProcessor < BaseTransactionProcessor
      protected

      def transaction_type
        "shipping_label"
      end

      def process_transaction
        create_shipping_label_payment_fee
      end

      private

      # 配送ラベル用のPaymentFeeレコードを作成
      def create_shipping_label_payment_fee
        # 既に同じtransaction_idの配送ラベル処理が存在する場合はスキップ
        if duplicate_shipping_label_fee?
          Rails.logger.debug "Skipping duplicate shipping label transaction: #{transaction['transactionId']}"
          return
        end

        fee_amount = transaction_amount
        Rails.logger.debug "Shipping label fee amount: #{fee_amount}"

        begin
          payment_fee = PaymentFee.create!(
            order: order,
            transaction_type: :shipping_label,
            transaction_id: transaction["transactionId"],
            fee_category: "undefined",
            fee_amount: fee_amount
          )
          Rails.logger.debug "Created shipping label PaymentFee: #{payment_fee.id}"
        rescue ActiveRecord::RecordNotUnique => e
          log_duplicate_error("配送ラベル")
        rescue => e
          log_creation_error("shipping label PaymentFee", e)
          raise
        end
      end

      # 配送ラベル手数料が重複しているかチェック
      # @return [Boolean] 重複しているかどうか
      def duplicate_shipping_label_fee?
        record_exists?(
          order: order,
          transaction_id: transaction["transactionId"],
          transaction_type: PaymentFee.transaction_types[:shipping_label]
        )
      end
    end
  end
end
