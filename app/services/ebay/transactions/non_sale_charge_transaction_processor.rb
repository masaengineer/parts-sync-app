module Ebay
  module Transactions
    class NonSaleChargeTransactionProcessor < BaseTransactionProcessor
      protected

      def transaction_type
        "non_sale_charge"
      end

      def process_transaction
        create_non_sale_charge_payment_fee
      end

      private

      def create_non_sale_charge_payment_fee
        unless transaction["feeType"] == "AD_FEE"
          Rails.logger.debug "Skipping non-AD_FEE transaction: #{transaction['transactionId']}, feeType: #{transaction['feeType']}"
          return
        end

        fee_category = transaction["feeType"]

        if duplicate_non_sale_charge_fee?(fee_category)
          Rails.logger.debug "Skipping duplicate non-sale charge transaction: #{transaction['transactionId']}"
          return
        end

        fee_amount = transaction_amount
        Rails.logger.debug "Non-sale charge fee amount: #{fee_amount}"

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
          log_duplicate_error("非販売手数料")
        rescue => e
          log_creation_error("non-sale charge PaymentFee", e)
          raise
        end
      end

      def duplicate_non_sale_charge_fee?(fee_category = nil)
        exists_params = {
          order: order,
          transaction_id: transaction["transactionId"],
          transaction_type: PaymentFee.transaction_types[:non_sale_charge]
        }

        exists_params[:fee_category] = fee_category if fee_category

        record_exists?(exists_params)
      end
    end
  end
end
