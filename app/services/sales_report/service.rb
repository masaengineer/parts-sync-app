module SalesReport
  class Service
    def initialize(order)
      @order = order
    end

    def calculate
      order_revenue_usd = @order.sales.sum(&:order_gross_amount).to_f

      exchange_rate = @order.sales.map(&:to_usd_rate).first.to_f
      exchange_rate = 1.0 if exchange_rate.zero?

      order_payment_fees_usd = @order.payment_fees.sum(&:fee_amount).to_f
      order_shipping_cost_jpy = safe_decimal_conversion(
        @order.shipment&.customer_international_shipping
      )
      procurement_data = calculate_procurement_data(@order)

      usd_revenue = order_revenue_usd * exchange_rate

      payment_fees_in_usd = order_payment_fees_usd

      net_revenue_usd = usd_revenue - payment_fees_in_usd
      usd_to_jpy_rate = 150.0

      net_revenue_jpy = net_revenue_usd * usd_to_jpy_rate

      net_revenue_usd = usd_revenue - payment_fees_in_usd
      net_revenue_jpy = net_revenue_usd * usd_to_jpy_rate

      total_jpy_costs = order_shipping_cost_jpy +
                        procurement_data[:procurement_cost] +
                        procurement_data[:other_costs]

      profit_jpy = net_revenue_jpy - total_jpy_costs
      jpy_revenue = usd_revenue * usd_to_jpy_rate
      profit_rate = jpy_revenue.zero? ? 0 : (profit_jpy / jpy_revenue) * 100

      order_lines = @order.order_lines
      sku_codes = order_lines.map { |line| line.seller_sku.sku_code }.compact.join(", ")
      product_names = order_lines.map(&:line_item_name).compact.join(", ")

      {
        order: @order,
        revenue: usd_revenue,
        payment_fees: payment_fees_in_usd,
        shipping_cost: order_shipping_cost_jpy,
        procurement_cost: procurement_data[:procurement_cost],
        other_costs: procurement_data[:other_costs],
        quantity: procurement_data[:total_quantity],
        profit: profit_jpy,
        profit_rate: profit_rate,
        tracking_number: @order.shipment&.tracking_number,
        sale_date: @order.sale_date,
        sku_codes: sku_codes,
        product_names: product_names,
        exchange_rate: exchange_rate
      }
    end

    private

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
