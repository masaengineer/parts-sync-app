module Ebay
  module Transactions
    # 非販売手数料取引処理クラス
    class NonSaleChargeTransactionProcessor < BaseTransactionProcessor
      protected

      def transaction_type
        'non_sale_charge'
      end

      def process_transaction
        create_non_sale_charge_payment_fee
      end

      private

      # 非販売手数料用のPaymentFeeレコードを作成
      def create_non_sale_charge_payment_fee
        # AD_FEE以外はスキップ
        unless transaction["feeType"] == "AD_FEE"
          Rails.logger.debug "Skipping non-AD_FEE transaction: #{transaction['transactionId']}, feeType: #{transaction['feeType']}"
          return
        end

        fee_category = transaction["feeType"]

        # 既に同じtransaction_idの非販売手数料処理が存在する場合はスキップ
        if duplicate_non_sale_charge_fee?(fee_category)
          Rails.logger.debug "Skipping duplicate non-sale charge transaction: #{transaction['transactionId']}"
          return
        end

        fee_amount = transaction_amount
        Rails.logger.debug "Non-sale charge fee amount: #{fee_amount}"

        # bookingEntry が CREDIT なら fee_amount を反転
        if transaction["bookingEntry"] == "CREDIT"
          fee_amount *= -1
          Rails.logger.debug "Reversed fee amount due to CREDIT booking entry: #{fee_amount}"
        end

        begin
          payment_fee = PaymentFee.create!(
            order: order,
            transaction_type: :non_sale_charge,
            transaction_id: transaction["transactionId"],
            fee_category: fee_category,
            fee_amount: fee_amount
          )
          Rails.logger.debug "Created non-sale charge PaymentFee: #{payment_fee.id}"
        rescue ActiveRecord::RecordNotUnique => e
          log_duplicate_error('非販売手数料')
        rescue => e
          log_creation_error('non-sale charge PaymentFee', e)
          raise
        end
      end

      # 非販売手数料が重複しているかチェック
      # @param fee_category [String] 手数料カテゴリ
      # @return [Boolean] 重複しているかどうか
      def duplicate_non_sale_charge_fee?(fee_category = nil)
        exists_params = {
          order: order,
          transaction_id: transaction["transactionId"],
          transaction_type: PaymentFee.transaction_types[:non_sale_charge]
        }

        # fee_categoryが指定されていれば条件に追加
        exists_params[:fee_category] = fee_category if fee_category

        record_exists?(exists_params)
      end
    end
  end
end
