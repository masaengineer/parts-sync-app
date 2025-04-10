module Ebay
  module Transactions
    class SaleTransactionProcessor < BaseTransactionProcessor
      protected

      def transaction_type
        "sale"
      end

      def process_transaction
        fee_processed = process_marketplace_fees
        create_sale_record if fee_processed
      end

      private

      def process_marketplace_fees
        fee_processed = false

        return fee_processed unless transaction["orderLineItems"].is_a?(Array)

        transaction["orderLineItems"].each_with_index do |item, idx|
          Rails.logger.debug "Processing orderLineItem #{idx}: #{item.keys.inspect}"

          unless valid_marketplace_fees?(item)
            Rails.logger.error "Invalid marketplaceFees for item #{idx}: #{item['marketplaceFees'].inspect}"
            next
          end

          item["marketplaceFees"].each_with_index do |fee, fee_idx|
            if process_single_fee(fee, idx, fee_idx)
              fee_processed = true
            end
          end
        end

        fee_processed
      end


      def process_single_fee(fee, item_idx, fee_idx)
        Rails.logger.debug "Processing fee #{fee_idx} of item #{item_idx}: #{fee.inspect}"

        fee_category = determine_fee_category(fee)
        Rails.logger.debug "Fee category determined as: #{fee_category}"

        if duplicate_fee?(fee_category)
          Rails.logger.debug "Skipping duplicate fee: transaction_id=#{transaction['transactionId']}, fee_category=#{fee_category}"
          return false
        end

        begin
          payment_fee = PaymentFee.create!(
            order: order,
            transaction_type: :sale,
            transaction_id: transaction["transactionId"],
            fee_category: fee_category,
            fee_amount: fee.dig("amount", "value").to_d
          )
          Rails.logger.debug "Created PaymentFee: #{payment_fee.id}"
          true
        rescue ActiveRecord::RecordNotUnique => e
          log_duplicate_error("個別処理")
          false
        rescue => e
          log_creation_error("PaymentFee", e)
          raise
        end
      end

      def determine_fee_category(fee)
        PaymentFee.fee_categories.values.include?(fee["feeType"]) ? fee["feeType"] : "undefined"
      end

      def duplicate_fee?(fee_category)
        record_exists?(
          transaction_id: transaction["transactionId"],
          transaction_type: PaymentFee.transaction_types[:sale],
          fee_category: fee_category
        )
      end

      def valid_marketplace_fees?(item)
        item["marketplaceFees"].is_a?(Array) && !item["marketplaceFees"].nil?
      end

      def create_sale_record
        return if Sale.where(order_id: order.id).where("order_net_amount > 0").exists?

        begin
          exchange_rate_value = transaction.dig("amount", "exchangeRate")
          exchange_rate = exchange_rate_value.nil? ? 1.0 : exchange_rate_value.to_d
          Rails.logger.debug "Exchange rate from API: #{exchange_rate}"

          sale = Sale.create!(
            order: order,
            order_net_amount: transaction_amount,
            order_gross_amount: total_fee_basis_amount,
            to_usd_rate: exchange_rate
          )
          Rails.logger.debug "Created Sale: #{sale.id}"
        rescue ActiveRecord::RecordNotUnique => e
          log_duplicate_error("Sale")
        rescue => e
          log_creation_error("Sale", e)
          raise
        end
      end
    end
  end
end
