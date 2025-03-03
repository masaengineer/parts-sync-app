module Ebay
  module Transactions
    # 全トランザクション処理クラスの基底クラス
    class BaseTransactionProcessor
      attr_reader :order, :transaction

      def initialize(order, transaction)
        @order = order
        @transaction = transaction
      end

      # トランザクションを処理
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

      # トランザクション固有の処理（サブクラスでオーバーライド）
      def process_transaction
        raise NotImplementedError, "サブクラスで実装する必要があります"
      end

      # トランザクション詳細をログに記録
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

      # 処理成功のログを記録
      def log_success
        Rails.logger.debug "#{transaction_type} transaction processing completed successfully"
      end

      # エラーをログに記録
      def log_error(exception)
        Rails.logger.error "予期せぬエラー: #{exception.class.name} - #{exception.message}"
        if exception.backtrace
          Rails.logger.error exception.backtrace.join("\n")
        end
      end

      # トランザクションの金額を取得
      def transaction_amount
        transaction.dig("amount", "value").to_d
      end

      # トランザクションの総手数料ベース金額を取得
      def total_fee_basis_amount
        transaction.dig("totalFeeBasisAmount", "value").to_d
      end

      # トランザクションの総手数料金額を取得
      def total_fee_amount
        transaction.dig("totalFeeAmount", "value").to_d
      end

      # トランザクションタイプを取得（サブクラスでオーバーライド）
      def transaction_type
        raise NotImplementedError, "サブクラスで実装する必要があります"
      end

      # 重複レコードチェック用の汎用メソッド
      def record_exists?(params)
        PaymentFee.exists?(params)
      end

      # 重複エラーを記録
      def log_duplicate_error(type)
        Rails.logger.warn "重複エラー (#{type}): transaction_id=#{transaction['transactionId']}"
      end

      # レコード作成エラーを記録
      def log_creation_error(type, exception)
        Rails.logger.error "Failed to create #{type}: #{exception.message}"
        if exception.backtrace
          Rails.logger.error exception.backtrace.join("\n")
        end
      end
    end
  end
end
