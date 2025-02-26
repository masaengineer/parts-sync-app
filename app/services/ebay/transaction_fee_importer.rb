require "logger"
require "stringio"

module Ebay
  class TransactionFeeImporter
    class ImportError < StandardError; end

    def initialize(api_client = FinanceApiClient.new)
      @api_client = api_client
      @log_output = StringIO.new
    end

    def import
      memory_logger = Logger.new(@log_output)
      memory_logger.formatter = Rails.logger.formatter

      transactions_data = @api_client.fetch_transactions
      memory_logger.info("Transactions data fetched: #{transactions_data.inspect}")

      begin
        process_transactions(transactions_data["transactions"], memory_logger)
      rescue StandardError => e
        memory_logger.error("❌ Transaction import error: #{e.message}")
        Rails.logger.error "❌ Transaction import error: #{e.message}"
        raise ImportError, "取引データのインポートに失敗しました: #{e.message}"
      end

      @log_output.string
    end

    private

    def process_transactions(transactions, logger)
      logger.info("🔄 トランザクション処理開始: 合計#{transactions.length}件")
      transactions.each do |transaction|
        logger.info("📎 トランザクション処理中: ID #{transaction['transactionId']}")

        order_number = find_order_number(transaction, logger)

        unless order_number
          logger.warn("⚠️ 注文番号なし: トランザクションID #{transaction['transactionId']}")
          next
        end

        order = Order.find_by(order_number: order_number)
        unless order
          logger.warn("⚠️ 注文が見つかりません: 注文番号 #{order_number}")
          next
        end

        case transaction["transactionType"]
        when "SALE"
          process_sale_transaction(order, transaction, logger)
        when "SHIPPING_LABEL"
          process_shipping_label_transaction(order, transaction, logger)
        when "NON_SALE_CHARGE"
          process_non_sale_charge_transaction(order, transaction, logger)
        when "REFUND"
          process_refund_transaction(order, transaction, logger)
        end
      end
      logger.info("✅ トランザクション処理完了")
    end

    def find_order_number(transaction, logger)
      logger.debug("🔍 find_order_number called with transactionType: #{transaction['transactionType']}")

      order_number = if transaction["transactionType"] == "NON_SALE_CHARGE"
        # references 配列から referenceType が ORDER_ID の要素を探す
        logger.debug("📦 NON_SALE_CHARGE: references = #{transaction['references'].inspect}")
        order_id_reference = transaction["references"]&.find { |ref| ref["referenceType"] == "ORDER_ID" }
        logger.debug("🏷️ Found order_id_reference: #{order_id_reference.inspect}")
        order_id_reference&.[]("referenceId")
      else
        # 通常の処理 (SALE, REFUND, SHIPPING_LABEL など)
        logger.debug("🛍️ Regular transaction: orderId = #{transaction['orderId']}")
        transaction["orderId"]
      end

      if order_number.nil? || order_number == "0"
        logger.warn("⚠️ 適切な orderId が見つかりません: transactionId=#{transaction['transactionId']}, transactionType=#{transaction['transactionType']}")
        return nil
      end

      order_number
    end

    def process_sale_transaction(order, transaction, logger)
      # PaymentFeeテーブルで既に同じtransaction_idの販売処理が存在する場合はスキップ
      if PaymentFee.exists?(
        order: order,
        transaction_id: transaction["transactionId"],
        transaction_type: PaymentFee.transaction_types[:sale]
      )
        logger.warn("⚠️ 既に処理済みの販売トランザクションをスキップ: transaction_id=#{transaction['transactionId']}")
        return
      end

      amount = transaction.dig("amount", "value").to_d
      total_fee_basis_amount = transaction.dig("totalFeeBasisAmount", "value").to_d

      logger.info("💰 販売処理: #{amount}ドル - 注文番号: #{order.order_number}")

      ActiveRecord::Base.transaction do
        # marketplaceFeesの情報をPaymentFeeとして登録
        transaction["orderLineItems"].each do |item|
          logger.info("  === marketplaceFees: #{item['marketplaceFees'].inspect}")
          item["marketplaceFees"].each do |fee|
            fee_category = PaymentFee.fee_categories.values.include?(fee["feeType"]) ? fee["feeType"] : "undefined"
            PaymentFee.create!(
              order: order,
              transaction_type: :sale,
              transaction_id: transaction["transactionId"],
              fee_category: fee_category,
              fee_amount: fee.dig("amount", "value").to_d
            )
          end
        end

        # PaymentFeeの作成に成功したら、Saleレコードも作成
        Sale.create!(
          order: order,
          order_net_amount: amount,
          order_gross_amount: total_fee_basis_amount
        )
      end

      logger.info("✅ SALEトランザクション保存完了: 注文番号 #{order.order_number}")
    rescue ActiveRecord::RecordNotUnique => e
      logger.error("⚠️ 重複する処理をスキップ: #{e.message}")
    end

    def process_shipping_label_transaction(order, transaction, logger)
      PaymentFee.find_or_create_by!(transaction_id: transaction["transactionId"]) do |payment_fee|
        payment_fee.order = order
        payment_fee.transaction_type = :shipping_label
        payment_fee.fee_category = :undefined
        payment_fee.fee_amount = transaction.dig("amount", "value").to_d
      end
      logger.info("✅ SHIPPING_LABELトランザクション保存完了: 注文番号 #{order.order_number}")
    end

    def process_non_sale_charge_transaction(order, transaction, logger)
      logger.info("📌 Processing NON_SALE_CHARGE: feeType=#{transaction['feeType']}")

      unless transaction["feeType"] == "AD_FEE"
        logger.info("📌 Skipping non AD_FEE: #{transaction['feeType']}")
        return
      end

      # 既存のレコードをチェック
      existing_fee = PaymentFee.find_by(
        transaction_id: transaction["transactionId"],
        transaction_type: :non_sale_charge,
        fee_category: transaction["feeType"]
      )

      if existing_fee
        logger.info("⚠️ 既存の手数料レコードが見つかりました: ID=#{existing_fee.id}")
        return
      end

      amount = transaction.dig("amount", "value").to_d
      logger.info("💰 広告料金処理: #{amount}ドル - 注文番号: #{order.order_number}, bookingEntry=#{transaction['bookingEntry']}")

      payment_fee = PaymentFee.new(
        order: order,
        transaction_type: :non_sale_charge,
        fee_category: transaction["feeType"],
        fee_amount: amount,
        transaction_id: transaction["transactionId"]
      )

      # bookingEntry が CREDIT なら fee_amount を反転
      payment_fee.fee_amount *= -1 if transaction["bookingEntry"] == "CREDIT"

      if payment_fee.save
        logger.info("✅ 広告料金保存完了")
      else
        logger.error("❌ 広告料金保存失敗: #{payment_fee.errors.full_messages}")
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.warn("⚠️ 重複する手数料レコードをスキップ: #{e.message}")
    end

    def process_refund_transaction(order, transaction, logger)
      unless transaction["bookingEntry"] == "DEBIT"
        logger.info("📌 DEBIT以外の返金をスキップ: #{transaction['bookingEntry']}")
        return
      end

      # PaymentFee で既に同じ transaction_id の返金が登録されている場合は処理をスキップ
      if PaymentFee.exists?(
        order: order,
        transaction_id: transaction["transactionId"],
        transaction_type: PaymentFee.transaction_types[:refund]
      )
        logger.warn("⚠️ 既に処理済みの返金トランザクションをスキップ: transaction_id=#{transaction['transactionId']}")
        return
      end

      amount = transaction.dig("amount", "value").to_d
      total_fee_basis_amount = transaction.dig("totalFeeBasisAmount", "value").to_d

      logger.info("💸 返金処理: #{amount}ドル - 注文番号: #{order.order_number}")
      logger.info("  amount: #{amount}, total_fee_basis_amount: #{total_fee_basis_amount}")

      # 返金用のSaleレコードを新規に作成（通常のSaleデータとは別に保存）
      Sale.create!(
        order: order,
        order_net_amount: -amount,
        order_gross_amount: -total_fee_basis_amount
      )

      PaymentFee.create!(
        order: order,
        transaction_type: :refund,
        fee_category: :undefined,
        fee_amount: -transaction.dig("totalFeeAmount", "value").to_d,
        transaction_id: transaction["transactionId"]
      )

      logger.info("✅ 返金処理完了")
    end
  end
end
