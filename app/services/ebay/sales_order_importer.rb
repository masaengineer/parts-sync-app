module Ebay
  class SalesOrderImporter
    def initialize(orders_data)
      @orders_data = orders_data
    end

    def import(current_user)
      ApplicationRecord.transaction do
        @orders_data[:orders].each do |ebay_order|
          import_order(ebay_order, current_user)
        end

        current_user.update!(ebay_orders_last_synced_at: @orders_data[:last_synced_at])
      end
    rescue ActiveRecord::RecordInvalid => e
      raise ::Ebay::EbaySalesOrderClient::FulfillmentError, "データ保存中にエラーが発生しました: #{e.message}"
    rescue StandardError => e
      raise ::Ebay::EbaySalesOrderClient::FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def import_order(order_data, current_user)
      return if current_user.blank?

      Rails.logger.info "[eBay Sync] Starting import for order #{order_data['orderId']}"

      currency_code = extract_currency_code(order_data)
      currency = nil
      if currency_code.present?
        currency = ::Currency.find_by(code: currency_code)
        if currency.nil?
          currency_name, currency_symbol = currency_info_for_code(currency_code)
          currency = ::Currency.create!(
            code: currency_code,
            name: currency_name,
            symbol: currency_symbol
          )
        end
      end

      order = Order.find_or_initialize_by(order_number: order_data["orderId"], user_id: current_user.id)
      was_new_order = order.new_record?
      order.update!(
        sale_date:  order_data["creationDate"],
        user_id:    current_user.id,
        currency_id: currency&.id
      )

      if was_new_order
        Rails.logger.info "[eBay Sync] Created new order (ID: #{order.id}) for #{order_data['orderId']}"
      else
        Rails.logger.info "[eBay Sync] Updated existing order (ID: #{order.id}) for #{order_data['orderId']}"
      end

      import_order_lines(order, order_data["lineItems"])
      import_shipment(order, order_data)
      
      Rails.logger.info "[eBay Sync] Completed import for order #{order_data['orderId']}"
    rescue => e
      Rails.logger.error "[eBay Sync] Failed to import order #{order_data['orderId']}: #{e.message}"
      Rails.logger.error "[eBay Sync] Backtrace: #{e.backtrace[0..3].join('\n')}"
      raise
    end

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

        sku_code = line_item["sku"].presence || "undefined"
        seller_sku = ::SellerSku.find_or_create_by!(sku_code: sku_code)

        if line_item["legacyItemId"].present? && seller_sku.item_id.blank?
          seller_sku.update(item_id: line_item["legacyItemId"])
        end

        attributes[:seller_sku_id] = seller_sku.id

        order_line.update!(attributes)
      end
    end

    def import_shipment(order, order_data)
      fulfillment_hrefs = order_data["fulfillmentHrefs"]

      Rails.logger.info "[eBay Sync] Processing shipment for order #{order_data['orderId']}"

      if fulfillment_hrefs.blank?
        Rails.logger.info "[eBay Sync] No fulfillmentHrefs for order #{order_data['orderId']}, skipping shipment import"
        return
      end

      tracking_number = fulfillment_hrefs[0].split("/").last
      Rails.logger.info "[eBay Sync] Extracted tracking number '#{tracking_number}' for order #{order_data['orderId']}"

      shipment = Shipment.find_or_initialize_by(order_id: order.id)
      was_new_record = shipment.new_record?
      
      shipment.update!(
        tracking_number: tracking_number
      )
      
      if was_new_record
        Rails.logger.info "[eBay Sync] Created new shipment (ID: #{shipment.id}) for order #{order_data['orderId']} with tracking #{tracking_number}"
      else
        Rails.logger.info "[eBay Sync] Updated existing shipment (ID: #{shipment.id}) for order #{order_data['orderId']} with tracking #{tracking_number}"
      end
    rescue => e
      Rails.logger.error "[eBay Sync] Failed to import shipment for order #{order_data['orderId']}: #{e.message}"
      Rails.logger.error "[eBay Sync] Backtrace: #{e.backtrace[0..3].join('\n')}"
      raise
    end

    def extract_currency_code(order_data)
      order_data.dig("pricingSummary", "total", "currency") ||
        order_data.dig("paymentSummary", "totalDueSeller", "convertedFromCurrency") ||
        "USD"
    end

    def currency_info_for_code(code)
      case code
      when "USD"
        [ "US Dollar", "$" ]
      when "JPY"
        [ "Japanese Yen", "¥" ]
      when "EUR"
        [ "Euro", "€" ]
      when "GBP"
        [ "British Pound", "£" ]
      when "CAD"
        [ "Canadian Dollar", "C$" ]
      when "AUD"
        [ "Australian Dollar", "A$" ]
      else
        [ "Unknown Currency (#{code})", code ]
      end
    end
  end
end
