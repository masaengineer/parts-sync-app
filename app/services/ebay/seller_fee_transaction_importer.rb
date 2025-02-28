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

        unless order_number
          next
        end

        order = Order.find_by(order_number: order_number)
        unless order
          next
        end

        case transaction["transactionType"]
        when "SALE"
          process_sale_transaction(order, transaction)
        when "SHIPPING_LABEL"
          process_shipping_label_transaction(order, transaction)
        when "NON_SALE_CHARGE"
          process_non_sale_charge_transaction(order, transaction)
        when "REFUND"
          process_refund_transaction(order, transaction)
        end
      end
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

      if order_number.nil? || order_number == "0"
        return nil
      end

      order_number
    end

    # 販売取引を処理
    # @param order [Order] 注文オブジェクト
    # @param transaction [Hash] 取引データ
    def process_sale_transaction(order, transaction)
      # PaymentFeeテーブルで既に同じtransaction_idの販売処理が存在する場合はスキップ
      if PaymentFee.exists?(
        order: order,
        transaction_id: transaction["transactionId"],
        transaction_type: PaymentFee.transaction_types[:sale]
      )
        return
      end

      amount = transaction.dig("amount", "value").to_d
      total_fee_basis_amount = transaction.dig("totalFeeBasisAmount", "value").to_d

      ActiveRecord::Base.transaction do
        # marketplaceFeesの情報をPaymentFeeとして登録
        transaction["orderLineItems"].each do |item|
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
    rescue ActiveRecord::RecordNotUnique => e
      # 重複エラーは無視
    end

    # 配送ラベル取引を処理
    # @param order [Order] 注文オブジェクト
    # @param transaction [Hash] 取引データ
    def process_shipping_label_transaction(order, transaction)
      PaymentFee.find_or_create_by!(transaction_id: transaction["transactionId"]) do |payment_fee|
        payment_fee.order = order
        payment_fee.transaction_type = :shipping_label
        payment_fee.fee_category = :undefined
        payment_fee.fee_amount = transaction.dig("amount", "value").to_d
      end
    end

    # 非販売手数料取引を処理
    # @param order [Order] 注文オブジェクト
    # @param transaction [Hash] 取引データ
    def process_non_sale_charge_transaction(order, transaction)
      unless transaction["feeType"] == "AD_FEE"
        return
      end

      # 既存のレコードをチェック
      existing_fee = PaymentFee.find_by(
        transaction_id: transaction["transactionId"],
        transaction_type: :non_sale_charge,
        fee_category: transaction["feeType"]
      )

      if existing_fee
        return
      end

      amount = transaction.dig("amount", "value").to_d

      payment_fee = PaymentFee.new(
        order: order,
        transaction_type: :non_sale_charge,
        fee_category: transaction["feeType"],
        fee_amount: amount,
        transaction_id: transaction["transactionId"]
      )

      # bookingEntry が CREDIT なら fee_amount を反転
      payment_fee.fee_amount *= -1 if transaction["bookingEntry"] == "CREDIT"

      payment_fee.save
    rescue ActiveRecord::RecordNotUnique => e
      # 重複エラーは無視
    end

    # 返金取引を処理
    # @param order [Order] 注文オブジェクト
    # @param transaction [Hash] 取引データ
    def process_refund_transaction(order, transaction)
      unless transaction["bookingEntry"] == "DEBIT"
        return
      end

      # PaymentFee で既に同じ transaction_id の返金が登録されている場合は処理をスキップ
      if PaymentFee.exists?(
        order: order,
        transaction_id: transaction["transactionId"],
        transaction_type: PaymentFee.transaction_types[:refund]
      )
        return
      end

      amount = transaction.dig("amount", "value").to_d
      total_fee_basis_amount = transaction.dig("totalFeeBasisAmount", "value").to_d

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
    end
  end
end
