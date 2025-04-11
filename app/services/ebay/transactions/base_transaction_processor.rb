module Ebay
  module Transactions
    class BaseTransactionProcessor
      attr_reader :order, :transaction

      def initialize(order, transaction)
        @order = order
        @transaction = transaction
      end

      def process
        log_transaction_details
        result = process_transaction
        log_success
        result
      rescue StandardError => e
        log_error(e)
        raise
      end

      protected

      def process_transaction
        raise NotImplementedError, "サブクラスで実装する必要があります"
      end

      def log_transaction_details
        Rails.logger.debug "Transaction keys: #{transaction.keys.inspect}"
        Rails.logger.debug "Transaction type: #{transaction['transactionType']}"
        Rails.logger.debug "Transaction ID: #{transaction['transactionId']}"

        amount = transaction.dig("amount", "value").to_d
        Rails.logger.debug "Amount: #{amount.inspect}"

        total_fee_basis_amount = transaction.dig("totalFeeBasisAmount", "value").to_d
        Rails.logger.debug "Total Fee Basis Amount: #{total_fee_basis_amount.inspect}"

        Rails.logger.debug "OrderLineItems count: #{transaction['orderLineItems']&.size || 'N/A'}"
      end

      def log_success
        Rails.logger.debug "#{transaction_type} transaction processing completed successfully"
      end

      def log_error(exception)
        Rails.logger.error "予期せぬエラー: #{exception.class.name} - #{exception.message}"
        if exception.backtrace
          Rails.logger.error exception.backtrace.join("\n")
        end
      end

      def transaction_amount
        transaction.dig("amount", "value").to_d
      end

      def total_fee_basis_amount
        transaction.dig("totalFeeBasisAmount", "value").to_d
      end

      def total_fee_amount
        transaction.dig("totalFeeAmount", "value").to_d
      end

      def transaction_type
        raise NotImplementedError, "サブクラスで実装する必要があります"
      end

      def record_exists?(params)
        PaymentFee.exists?(params)
      end

      def log_duplicate_error(type)
        Rails.logger.warn "重複エラー (#{type}): transaction_id=#{transaction['transactionId']}"
      end

      def log_creation_error(type, exception)
        Rails.logger.error "Failed to create #{type}: #{exception.message}"
        if exception.backtrace
          Rails.logger.error exception.backtrace.join("\n")
        end
      end
    end
  end
end
