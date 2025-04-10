module Ebay
  module Transactions
    class RefundTransactionProcessor < BaseTransactionProcessor
      protected

      def transaction_type
        "refund"
      end

      def process_transaction
        create_refund_payment_fee
      end

      private

      def create_refund_payment_fee
        unless transaction["bookingEntry"] == "DEBIT"
          Rails.logger.debug "Skipping non-DEBIT refund transaction: #{transaction['transactionId']}, bookingEntry: #{transaction['bookingEntry']}"
          return
        end

        if duplicate_refund_fee?
          Rails.logger.debug "Skipping duplicate refund transaction: #{transaction['transactionId']}"
          return
        end

        amount = transaction_amount
        Rails.logger.debug "Refund amount: #{amount}"

        fee_basis_amount = total_fee_basis_amount
        Rails.logger.debug "Refund total fee basis amount: #{fee_basis_amount}"

        fee_amount = total_fee_amount
        Rails.logger.debug "Refund fee amount: #{fee_amount}"

        begin
          ActiveRecord::Base.transaction do
            sale = Sale.create!(
              order: order,
              order_net_amount: -amount,
              order_gross_amount: -fee_basis_amount
            )
            Rails.logger.debug "Created refund Sale: #{sale.id}"

            payment_fee = PaymentFee.create!(
              order: order,
              transaction_type: :refund,
              transaction_id: transaction["transactionId"],
              fee_category: "undefined",
              fee_amount: -fee_amount
            )
            Rails.logger.debug "Created refund PaymentFee: #{payment_fee.id}"
          end
        rescue ActiveRecord::RecordNotUnique => e
          log_duplicate_error("返金")
        rescue => e
          log_creation_error("refund records", e)
          raise
        end
      end

      def duplicate_refund_fee?
        record_exists?(
          order: order,
          transaction_id: transaction["transactionId"],
          transaction_type: PaymentFee.transaction_types[:refund]
        )
      end
    end
  end
end
