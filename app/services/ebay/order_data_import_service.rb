module Ebay
  class OrderDataImportService
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
      raise ::Ebay::FulfillmentService::FulfillmentError, "データ保存中にエラーが発生しました: #{e.message}"
    rescue StandardError => e
      raise ::Ebay::FulfillmentService::FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    # 個別の注文データを処理
    # @param order_data [Hash] eBayから取得した注文データ
    # @param current_user [User] 現在のユーザー
    def import_order(order_data, current_user)
      return if current_user.blank?

      order = Order.find_or_initialize_by(order_number: order_data["orderId"], user_id: current_user.id)
      order.update!(
        sale_date:  order_data["creationDate"],
        user_id:    current_user.id
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

        order_line = OrderLine.find_or_initialize_by(
          order_id: order.id,
          line_item_id: line_item["lineItemId"]
        )

        attributes = {
          quantity: line_item["quantity"],
          unit_price: line_item["total"]["value"],
          line_item_name: line_item["title"],
          line_item_id: line_item["lineItemId"]
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

      shipment = Shipment.find_or_initialize_by(order_id: order.id)
      shipment.update!(
        tracking_number: tracking_number
      )
    end
  end
end
