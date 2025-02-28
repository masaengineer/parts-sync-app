module Ebay
  class SalesOrderImporter
    def initialize(orders_data)
      @orders_data = orders_data
    end

    # eBayの注文データをインポート
    # @param current_user [User] 現在のユーザー
    def import(current_user)
      ApplicationRecord.transaction do
        @orders_data[:orders].each do |ebay_order|
          import_order(ebay_order, current_user)
        end

        # 最終同期日時を更新
        current_user.update!(ebay_orders_last_synced_at: @orders_data[:last_synced_at])
      end
    rescue ActiveRecord::RecordInvalid => e
      raise ::Ebay::EbaySalesOrderClient::FulfillmentError, "データ保存中にエラーが発生しました: #{e.message}"
    rescue StandardError => e
      raise ::Ebay::EbaySalesOrderClient::FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    # 個別の注文データを処理
    # @param order_data [Hash] eBayから取得した注文データ
    # @param current_user [User] 現在のユーザー
    def import_order(order_data, current_user)
      return if current_user.blank?

      # 通貨情報を取得
      currency_code = extract_currency_code(order_data)
      currency = ::Currency.find_or_create_by_code(currency_code) if currency_code.present?

      order = Order.find_or_initialize_by(order_number: order_data["orderId"], user_id: current_user.id)
      order.update!(
        sale_date:  order_data["creationDate"],
        user_id:    current_user.id,
        currency_id: currency&.id
      )

      import_order_lines(order, order_data["lineItems"])
      import_shipment(order, order_data)
    end

    # 注文の明細行を処理
    # @param order [Order] 注文オブジェクト
    # @param line_items [Array] 注文明細行の配列
    def import_order_lines(order, line_items)
      line_items.each do |line_item|
        next unless line_item
        next unless line_item["quantity"] && line_item["total"] && line_item["total"]["value"]

        # 各明細行の通貨情報を取得
        currency_code = line_item.dig("total", "currency")
        currency = currency_code.present? ? ::Currency.find_or_create_by_code(currency_code) : order.currency

        order_line = OrderLine.find_or_initialize_by(
          order_id: order.id,
          line_item_id: line_item["lineItemId"]
        )

        attributes = {
          quantity: line_item["quantity"],
          unit_price: line_item["total"]["value"],
          line_item_name: line_item["title"],
          line_item_id: line_item["lineItemId"],
          currency_id: currency&.id
        }

        # SKUが存在する場合はそのSKUを、存在しない場合は"undefined"を使用
        sku_code = line_item["sku"].presence || "undefined"
        seller_sku = ::SellerSku.find_or_create_by!(sku_code: sku_code)
        attributes[:seller_sku_id] = seller_sku.id

        order_line.update!(attributes)
      end
    end

    # 出荷情報を処理
    # @param order [Order] 注文オブジェクト
    # @param order_data [Hash] 注文データ
    def import_shipment(order, order_data)
      fulfillment_hrefs = order_data["fulfillmentHrefs"]

      if fulfillment_hrefs.blank?
        return
      end

      tracking_number = fulfillment_hrefs[0].split("/").last

      # 注文の通貨情報をShipmentにも設定
      currency = order.currency

      shipment = Shipment.find_or_initialize_by(order_id: order.id)
      shipment.update!(
        tracking_number: tracking_number,
        currency_id: currency&.id
      )
    end

    # 注文データから通貨コードを抽出
    # @param order_data [Hash] 注文データ
    # @return [String, nil] 通貨コード
    def extract_currency_code(order_data)
      # 優先順位：価格サマリーの合計 > 支払いサマリーの合計 > デフォルト(USD)
      order_data.dig("pricingSummary", "total", "currency") ||
        order_data.dig("paymentSummary", "totalDueSeller", "currency") ||
        "USD"
    end
  end
end
