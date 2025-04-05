module SalesReport
  class Service
    def initialize(order)
      @order = order
    end

    def calculate
      # --- 売上 ---
      order_revenue_usd = @order.sales.sum(&:order_gross_amount).to_f

      # --- 為替レート ---
      exchange_rate = @order.sales.map(&:to_usd_rate).first.to_f
      exchange_rate = 1.0 if exchange_rate.zero? # レートが無い場合はデフォルト値

      # --- 手数料合計 ---
      order_payment_fees_usd = @order.payment_fees.sum(&:fee_amount).to_f

      # --- 送料(円) ---
      order_shipping_cost_jpy = safe_decimal_conversion(
        @order.shipment&.customer_international_shipping
      )

      # --- 調達コスト(円)とSKU合計数量 ---
      procurement_data = calculate_procurement_data(@order)

      # --- USD売上の計算 ---
      usd_revenue = order_revenue_usd * exchange_rate

      # --- 手数料をUSDで計算 ---
      payment_fees_in_usd = order_payment_fees_usd

      # --- USD売上から手数料を引いた純売上をJPYに変換 ---
      net_revenue_usd = usd_revenue - payment_fees_in_usd
      # 固定レート 1 USD = 150 JPY を使用
      usd_to_jpy_rate = 150.0

      # --- USD売上の計算（order_gross_amount × to_usd_rate） ---
      usd_revenue = order_revenue_usd * exchange_rate

      # --- USD売上から手数料を引いた純売上をJPYに変換 ---
      net_revenue_usd = usd_revenue - payment_fees_in_usd
      net_revenue_jpy = net_revenue_usd * usd_to_jpy_rate

      # --- 円建てコストの合計 ---
      total_jpy_costs = order_shipping_cost_jpy +
                        procurement_data[:procurement_cost] +
                        procurement_data[:other_costs]

      # --- 利益計算（JPY） ---
      profit_jpy = net_revenue_jpy - total_jpy_costs
      # 利益率計算も USD 売上を JPY に変換して計算
      jpy_revenue = usd_revenue * usd_to_jpy_rate
      profit_rate = jpy_revenue.zero? ? 0 : (profit_jpy / jpy_revenue) * 100

      # --- SKU情報の取得 ---
      order_lines = @order.order_lines
      sku_codes = order_lines.map { |line| line.seller_sku.sku_code }.compact.join(", ")
      product_names = order_lines.map(&:line_item_name).compact.join(", ")

      {
        order: @order,
        revenue: usd_revenue,                         # USD売上
        payment_fees: payment_fees_in_usd,            # USD手数料
        shipping_cost: order_shipping_cost_jpy,       # 円
        procurement_cost: procurement_data[:procurement_cost], # 仕入原価（円）
        other_costs: procurement_data[:other_costs],  # その他原価（円）
        quantity: procurement_data[:total_quantity],
        profit: profit_jpy,                           # JPY利益
        profit_rate: profit_rate,                     # %
        tracking_number: @order.shipment&.tracking_number, # 追跡番号
        sale_date: @order.sale_date,                  # 販売日
        sku_codes: sku_codes,                         # SKUコード（カンマ区切り）
        product_names: product_names,                 # 商品名（カンマ区切り）
        exchange_rate: exchange_rate                  # 為替レート
      }
    end

    private

    # 調達コストの計算（注文に紐づく調達情報から計算）
    def calculate_procurement_data(order)
      result = {
        procurement_cost: 0,  # 仕入原価（purchase_price）
        other_costs: 0,      # その他原価（forwarding_fee + handling_fee）
        total_quantity: 0
      }

      if procurement = order.procurement
        # 仕入原価の計算（商品の実際の仕入れ価格）
        result[:procurement_cost] = safe_decimal_conversion(procurement.purchase_price)

        # その他原価の計算（転送料 + 取扱手数料）- オプション料は除外
        result[:other_costs] = [
          safe_decimal_conversion(procurement.forwarding_fee), # 転送料
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
end
