module SalesReport
  class Service
    include ExchangeRateConcern

    def initialize(order)
      @order = order
    end

    def calculate
      sales_data = fetch_sales_data
      fees_data = fetch_fees_data
      shipping_cost = fetch_shipping_cost
      procurement_data = calculate_procurement_data(@order)

      # USD・JPY変換を実行
      revenue_conversions = calculate_revenue_conversions(sales_data)

      # 利益計算
      profit_data = calculate_profit(revenue_conversions, fees_data[:total_fees], shipping_cost, procurement_data)

      # 商品情報の取得s
      product_info = fetch_product_info

      build_result(
        sales_data: sales_data,
        revenue_conversions: revenue_conversions,
        fees_data: fees_data,
        shipping_cost: shipping_cost,
        procurement_data: procurement_data,
        profit_data: profit_data,
        product_info: product_info
      )
    end

    private

    def calculate_revenue_conversions(sales_data)
      revenue_original_currency = sales_data[:order_gross_amount]
      revenue_usd = convert_to_usd(sales_data)
      usd_to_jpy_rate = fetch_exchange_rate
      revenue_jpy = revenue_usd * usd_to_jpy_rate

      {
        original_currency: revenue_original_currency,
        usd: revenue_usd,
        jpy: revenue_jpy,
        usd_to_jpy_rate: usd_to_jpy_rate
      }
    end

    def calculate_profit(revenue_conversions, total_fees, shipping_cost, procurement_data)
      net_revenue_usd = revenue_conversions[:usd] - total_fees
      net_revenue_jpy = net_revenue_usd * revenue_conversions[:usd_to_jpy_rate]
      total_costs_jpy = calculate_total_costs(shipping_cost, procurement_data)
      profit_jpy = net_revenue_jpy - total_costs_jpy
      profit_rate = calculate_profit_rate(profit_jpy, revenue_conversions[:jpy])

      {
        jpy: profit_jpy,
        rate: profit_rate,
        net_revenue_jpy: net_revenue_jpy
      }
    end

    def fetch_sales_data
      sales = @order.sales
      order_gross_amount = sales.sum(&:order_gross_amount).to_f
      exchange_rate = sales.first&.to_usd_rate.to_f
      exchange_rate = 1.0 if exchange_rate.zero?

      {
        sales: sales,
        order_gross_amount: order_gross_amount,
        exchange_rate: exchange_rate
      }
    end

    def fetch_fees_data
      payment_fees = @order.payment_fees
      total_fees = payment_fees.sum(&:fee_amount).to_f

      {
        payment_fees: payment_fees,
        total_fees: total_fees
      }
    end

    def fetch_shipping_cost
      return 0 unless @order.shipment&.customer_international_shipping

      amount = safe_decimal_conversion(@order.shipment.customer_international_shipping)
      currency_code = @order.shipment.currency&.code

      # USDの場合は円に変換
      if currency_code == "USD"
        amount * fetch_exchange_rate
      else
        amount # JPYまたは通貨未設定の場合はそのまま
      end
    end

    def convert_to_usd(sales_data)
      # 元通貨の売上額をUSDに変換
      sales_data[:order_gross_amount] * sales_data[:exchange_rate]
    end

    def fetch_exchange_rate
      user = @order.user
      year = @order.sale_date&.year
      month = @order.sale_date&.month

      if user && year && month
        ExchangeRate.rate_for(user, year, month)
      else
        USD_TO_JPY_RATE
      end
    end

    def calculate_total_costs(shipping_cost, procurement_data)
      shipping_cost +
      procurement_data[:procurement_cost] +
      procurement_data[:other_costs]
    end

    def calculate_profit_rate(profit_jpy, revenue_jpy)
      revenue_jpy.zero? ? 0 : (profit_jpy / revenue_jpy) * 100
    end

    def fetch_product_info
      order_lines = @order.order_lines
      {
        sku_codes: order_lines.map { |line| line.seller_sku&.sku_code }.compact.join(", "),
        product_names: order_lines.map(&:line_item_name).compact.join(", ")
      }
    end

    def build_result(sales_data:, revenue_conversions:, fees_data:, shipping_cost:, procurement_data:, profit_data:, product_info:)
      {
        order: @order,
        revenue: revenue_conversions[:usd], # 後方互換性のため
        revenue_original_currency: revenue_conversions[:original_currency],
        revenue_usd: revenue_conversions[:usd],
        revenue_jpy: revenue_conversions[:jpy],
        payment_fees: fees_data[:total_fees],
        shipping_cost: shipping_cost,
        procurement_cost: procurement_data[:procurement_cost],
        other_costs: procurement_data[:other_costs],
        quantity: procurement_data[:total_quantity],
        profit: profit_data[:jpy],
        profit_rate: profit_data[:rate],
        tracking_number: @order.shipment&.tracking_number,
        sale_date: @order.sale_date,
        sku_codes: product_info[:sku_codes],
        product_names: product_info[:product_names],
        exchange_rate: sales_data[:exchange_rate],
        usd_to_jpy_rate: revenue_conversions[:usd_to_jpy_rate]
      }
    end

    def calculate_procurement_data(order)
      result = {
        procurement_cost: 0,
        other_costs: 0,
        total_quantity: 0
      }

      if procurement = order.procurement
        result[:procurement_cost] = safe_decimal_conversion(procurement.purchase_price)

        result[:other_costs] = [
          safe_decimal_conversion(procurement.forwarding_fee),
          safe_decimal_conversion(procurement.handling_fee)
        ].sum
      end

      order.order_lines.each do |line|
        result[:total_quantity] += line.quantity.to_i
      end

      result
    end

    def safe_decimal_conversion(value)
      return 0 if value.nil?
      BigDecimal(value.to_s).to_f
    rescue ArgumentError
      0
    end
  end
end
