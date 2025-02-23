# 売上・コスト・利益などをまとめて計算するサービスクラス。
# USD_TO_JPYレートを用いてドル建て→円建ての利益計算なども共通化できるようにする。
#
# 例:
#   result = SalesReportCalculator.new(order).calculate
#   => {
#        order: <Order ...>,
#        revenue: 売上(USD),
#        payment_fees: 手数料合計(USD),
#        shipping_cost: 送料(円),
#        procurement_cost: 仕入原価(円),      # purchase_price
#        other_costs: その他原価(円),         # forwarding_fee + option_fee + handling_fee
#        quantity: SKUの合計数量,
#        profit: 利益(円),
#        profit_rate: 利益率(％),
#        tracking_number: 追跡番号,
#        sale_date: 販売日,
#        sku_codes: SKUコード（カンマ区切り）,
#        product_names: 商品名（カンマ区切り）
#      }
#
class SalesReportCalculator
  include ExchangeRateConcern

  def initialize(order)
    @order = order
  end

  # 計算を実行し、ハッシュ形式で返す
  def calculate
    # --- 売上(USD) ---
    order_revenue_usd      = @order.sales.sum(&:order_net_amount).to_f

    # --- 手数料合計(USD) ---
    order_payment_fees_usd = @order.payment_fees.sum(&:fee_amount).to_f

    # --- 送料(円) ---
    order_shipping_cost_jpy = safe_decimal_conversion(
      @order.shipment&.customer_international_shipping
    )

    # --- 調達コスト(円)とSKU合計数量 ---
    procurement_data = calculate_procurement_data(@order)

    # --- ドルから円へ換算して利益計算 ---
    revenue_in_jpy      = convert_usd_to_jpy(order_revenue_usd)
    payment_fees_in_jpy = convert_usd_to_jpy(order_payment_fees_usd)

    # 総コストの計算（仕入原価 + その他原価 + 手数料 + 送料）
    total_cost_jpy = payment_fees_in_jpy +
                      order_shipping_cost_jpy +
                      procurement_data[:procurement_cost] +
                      procurement_data[:other_costs]

    profit_jpy = revenue_in_jpy - total_cost_jpy
    profit_rate = revenue_in_jpy.zero? ? 0 : (profit_jpy / revenue_in_jpy) * 100

    # --- SKU情報の取得 ---
    order_lines = @order.order_lines
    sku_codes = order_lines.map { |line| line.seller_sku.sku_code }.compact.join(", ")
    product_names = order_lines.map(&:line_item_name).compact.join(", ")

    {
      order: @order,
      revenue: order_revenue_usd,                       # 表示上ドルのまま
      payment_fees: order_payment_fees_usd,             # 表示上ドルのまま
      shipping_cost: order_shipping_cost_jpy,           # 円
      procurement_cost: procurement_data[:procurement_cost], # 仕入原価（円）
      other_costs: procurement_data[:other_costs],      # その他原価（円）
      quantity: procurement_data[:total_quantity],
      profit: profit_jpy,                               # 円
      profit_rate: profit_rate,                         # %
      tracking_number: @order.shipment&.tracking_number, # 追跡番号
      sale_date: @order.sale_date,                      # 販売日
      sku_codes: sku_codes,                             # SKUコード（カンマ区切り）
      product_names: product_names                      # 商品名（カンマ区切り）
    }
  end

  private

  # 調達コストの計算（注文に紐づく調達情報から計算）
  def calculate_procurement_data(order)
    result = {
      procurement_cost: 0,  # 仕入原価（purchase_price）
      other_costs: 0,      # その他原価（forwarding_fee + option_fee + handling_fee）
      total_quantity: 0
    }

    if procurement = order.procurement
      # 仕入原価の計算（商品の実際の仕入れ価格）
      result[:procurement_cost] = safe_decimal_conversion(procurement.purchase_price)

      # その他原価の計算（転送料 + オプション料 + 取扱手数料）
      result[:other_costs] = [
        safe_decimal_conversion(procurement.forwarding_fee), # 転送料
        safe_decimal_conversion(procurement.option_fee),      # オプション料
        safe_decimal_conversion(procurement.handling_fee)    # 取扱手数料
      ].sum
    end

    # SKUの数量は従来通りSKUから取得
    order.order_lines.each do |line|
      result[:total_quantity] += line.quantity.to_i
    end

    result
  end

  # 数値変換を安全に行う
  def safe_decimal_conversion(value)
    return 0 if value.nil?
    BigDecimal(value.to_s).to_f
  rescue ArgumentError
    0
  end
end
