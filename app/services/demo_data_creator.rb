class DemoDataCreator
  def initialize(target_user)
    @target_user = target_user
    @source_user_id = 1
  end

  def create_demo_data
    source_user = User.find_by(id: @source_user_id)
    return false unless source_user

    ActiveRecord::Base.transaction do
      copy_orders(source_user)
    end

    true
  rescue => e
    Rails.logger.error "デモデータの作成に失敗しました: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end

  private

  def copy_orders(source_user)
    source_user.orders.find_each do |source_order|
      new_order = copy_order(source_order)

      copy_order_lines(source_order, new_order)

      copy_procurement(source_order, new_order)

      copy_sales(source_order, new_order)

      copy_shipment(source_order, new_order)

      copy_payment_fees(source_order, new_order)
    end
  end

  def copy_order(source_order)
    demo_order_number = "DEMO-#{Time.current.to_i}-#{source_order.order_number}"

    Order.create!(
      user: @target_user,
      order_number: demo_order_number,
      sale_date: source_order.sale_date,
      currency: source_order.currency
    )
  end

  def copy_order_lines(source_order, new_order)
    source_order.order_lines.each do |source_line|
      original_seller_sku = source_line.seller_sku

      new_seller_sku = find_or_create_seller_sku(original_seller_sku)

      copy_sku_mappings(original_seller_sku, new_seller_sku)

      copy_price_adjustments(original_seller_sku, new_seller_sku)

      OrderLine.create!(
        order: new_order,
        seller_sku: new_seller_sku,
        quantity: source_line.quantity,
        unit_price: source_line.unit_price,
        line_item_id: "DEMO-#{Time.current.to_i}-#{source_line.line_item_id}",
        line_item_name: modify_title(source_line.line_item_name)
      )
    end
  end

  def find_or_create_seller_sku(original_sku)
    demo_sku_code = "DEMO-#{original_sku.sku_code}"

    existing_sku = SellerSku.find_by(sku_code: demo_sku_code)
    return existing_sku if existing_sku

    SellerSku.create!(
      sku_code: demo_sku_code,
      quantity: original_sku.quantity,
      item_id: original_sku.item_id.present? ? "DEMO-#{original_sku.item_id}" : nil
    )
  end

  def copy_sku_mappings(original_sku, new_sku)
    original_sku.sku_mappings.each do |mapping|
      SkuMapping.create!(
        seller_sku: new_sku,
        manufacturer_sku: mapping.manufacturer_sku
      )
    end
  end

  def copy_price_adjustments(original_sku, new_sku)
    original_sku.price_adjustments.each do |adjustment|
      PriceAdjustment.create!(
        seller_sku: new_sku,
        adjustment_date: adjustment.adjustment_date,
        adjustment_amount: adjustment.adjustment_amount,
        notes: "#{adjustment.notes} (DEMO)",
        currency: adjustment.currency
      )
    end
  end

  def copy_procurement(source_order, new_order)
    source_procurement = source_order.procurement
    return unless source_procurement

    Procurement.create!(
      order: new_order,
      purchase_price: source_procurement.purchase_price,
      forwarding_fee: source_procurement.forwarding_fee,
      handling_fee: source_procurement.handling_fee
    )
  end

  def copy_sales(source_order, new_order)
    source_order.sales.each do |source_sale|
      Sale.create!(
        order: new_order,
        order_net_amount: source_sale.order_net_amount,
        order_gross_amount: source_sale.order_gross_amount,
        to_usd_rate: source_sale.to_usd_rate,
        transaction_id: "DEMO-#{Time.current.to_i}-#{source_sale.transaction_id}"
      )
    end
  end

  def copy_shipment(source_order, new_order)
    source_shipment = source_order.shipment
    return unless source_shipment

    Shipment.create!(
      order: new_order,
      customer_international_shipping: source_shipment.customer_international_shipping,
      tracking_number: source_shipment.tracking_number ? "DEMO#{source_shipment.tracking_number}" : nil,
      currency: source_shipment.currency
    )
  end

  def copy_payment_fees(source_order, new_order)
    source_order.payment_fees.each do |source_fee|
      PaymentFee.create!(
        order: new_order,
        fee_category: source_fee.fee_category,
        fee_amount: source_fee.fee_amount,
        transaction_type: source_fee.transaction_type,
        transaction_id: "DEMO-#{Time.current.to_i}-#{source_fee.transaction_id}"
      )
    end
  end

  def modify_title(original_title)
    return "デモ: #{original_title}" if original_title.present?
    "デモデータ"
  end
end
