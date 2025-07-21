module SalesReport
  class Service
    include ExchangeRateConcern

    def initialize(order)
      @order = order
    end

    def calculate
      # Step 1: 基本データの取得
      sales_data = fetch_sales_data
      fees_data = fetch_fees_data
      shipping_cost = fetch_shipping_cost
      procurement_data = calculate_procurement_data(@order)

      # Step 2: USD計算
      usd_revenue = calculate_usd_revenue(sales_data)
      net_revenue_usd = usd_revenue - fees_data[:total_fees]

      # Step 3: 為替レート取得とJPY変換
      usd_to_jpy_rate = fetch_exchange_rate
      revenue_jpy = usd_revenue * usd_to_jpy_rate
      net_revenue_jpy = net_revenue_usd * usd_to_jpy_rate

      # Step 4: コスト計算
      total_costs_jpy = calculate_total_costs(shipping_cost, procurement_data)

      # Step 5: 利益計算
      profit_jpy = net_revenue_jpy - total_costs_jpy
      profit_rate = calculate_profit_rate(profit_jpy, revenue_jpy)

      # Step 6: 商品情報の取得
      product_info = fetch_product_info

      # Step 7: 結果の構築
      build_result(
        sales_data: sales_data,
        usd_revenue: usd_revenue,
        fees_data: fees_data,
        shipping_cost: shipping_cost,
        procurement_data: procurement_data,
        profit_jpy: profit_jpy,
        profit_rate: profit_rate,
        product_info: product_info,
        usd_to_jpy_rate: usd_to_jpy_rate
      )
    end

    private

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

      # 通貨がUSDの場合は円に変換
      if currency_code == "USD"
        amount * fetch_exchange_rate
      else
        # JPYまたは通貨が未設定の場合はそのまま返す
        amount
      end
    end

    def calculate_usd_revenue(sales_data)
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

    def build_result(sales_data:, usd_revenue:, fees_data:, shipping_cost:, procurement_data:, profit_jpy:, profit_rate:, product_info:, usd_to_jpy_rate:)
      {
        order: @order,
        revenue: usd_revenue,
        payment_fees: fees_data[:total_fees],
        shipping_cost: shipping_cost,
        procurement_cost: procurement_data[:procurement_cost],
        other_costs: procurement_data[:other_costs],
        quantity: procurement_data[:total_quantity],
        profit: profit_jpy,
        profit_rate: profit_rate,
        tracking_number: @order.shipment&.tracking_number,
        sale_date: @order.sale_date,
        sku_codes: product_info[:sku_codes],
        product_names: product_info[:product_names],
        exchange_rate: sales_data[:exchange_rate],
        usd_to_jpy_rate: usd_to_jpy_rate
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
