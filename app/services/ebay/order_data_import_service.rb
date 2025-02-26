module Ebay
  class OrderDataImportService
    def initialize(orders_data)
      @orders_data = orders_data
      Rails.logger.info "🚀 Ebay::OrderDataImportService initialized with #{@orders_data[:orders]&.size || 0} orders"
    end

    def import(current_user)
      Rails.logger.info "📥 Starting import for user: #{current_user.email} (ID: #{current_user.id})"
      ApplicationRecord.transaction do
        @orders_data[:orders].each do |ebay_order|
          import_order(ebay_order, current_user)
        end

        # カラム名を新しいものに修正
        current_user.update!(ebay_orders_last_synced_at: @orders_data[:last_synced_at])
      end
      Rails.logger.info "✅ Import completed successfully"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "❌ データ保存エラー: #{e.message}\n#{e.backtrace.join("\n")}"
      raise ::Ebay::FulfillmentService::FulfillmentError, "データ保存中にエラーが発生しました: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "💥 予期せぬエラー: #{e.message}\n#{e.backtrace.join("\n")}"
      raise ::Ebay::FulfillmentService::FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def import_order(order_data, current_user)
      Rails.logger.info "📦 Processing order #{order_data['orderId']} for user #{current_user.email}"
      return if current_user.blank?

      order = Order.find_or_initialize_by(order_number: order_data["orderId"], user_id: current_user.id)
      order.update!(
        sale_date:  order_data["creationDate"],
        user_id:    current_user.id
      )
      Rails.logger.info "💾 Order #{order.order_number} #{order.new_record? ? 'created' : 'updated'}"

      import_order_lines(order, order_data["lineItems"])
      import_shipment(order, order_data)
    end

    def import_order_lines(order, line_items)
      Rails.logger.info "📝 Processing #{line_items&.size || 0} line items for order #{order.order_number}"
      line_items.each do |line_item|
        Rails.logger.debug "➡️ Processing line item: #{line_item['lineItemId']}"

        unless line_item
          Rails.logger.error "⚠️ Skipping nil line item"
          next
        end

        unless line_item["quantity"] && line_item["total"] && line_item["total"]["value"]
          Rails.logger.error "⚠️ Missing required data for line item #{line_item['lineItemId']}"
          next
        end

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
        Rails.logger.debug "🏷️ SellerSku: #{seller_sku.sku_code}"
        attributes[:seller_sku_id] = seller_sku.id

        order_line.update!(attributes)
        Rails.logger.info "✅ Line item #{order_line.line_item_id} #{order_line.new_record? ? 'created' : 'updated'}"
      end
    end

    def import_shipment(order, order_data)
      Rails.logger.info "🚚 Processing shipment for order #{order.order_number}"
      fulfillment_hrefs = order_data["fulfillmentHrefs"]

      if fulfillment_hrefs.blank?
        Rails.logger.warn "⚠️ No fulfillment href found for order #{order.order_number}"
        return
      end

      tracking_number = fulfillment_hrefs[0].split("/").last

      shipment = Shipment.find_or_initialize_by(order_id: order.id)
      shipment.update!(
        tracking_number: tracking_number
      )
      Rails.logger.info "📦 Shipment #{shipment.new_record? ? 'created' : 'updated'} with tracking number: #{tracking_number}"
    end
  end
end
