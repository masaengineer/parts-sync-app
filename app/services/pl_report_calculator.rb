class PlReportCalculator
  def initialize(order)
    @order = order
  end

  def calculate
    {
      revenue: calculate_revenue,
      payment_fees: calculate_payment_fees,
      shipping_cost: calculate_shipping_cost,
      procurement_cost: calculate_procurement_cost
    }
  end

  def calculate_monthly_data
    orders = fetch_orders
    initialize_monthly_data.tap do |monthly_data|
      aggregate_orders(orders, monthly_data)
      calculate_metrics(monthly_data)
    end
  end

  private

  def fetch_orders
    Order.where("extract(year from sale_date) = ?", @order.sale_date.year)
         .includes(
           :sales,
           :shipment,
           :payment_fees,
           :procurement,
           order_lines: { seller_sku: :manufacturer_skus }
         )
  end

  def initialize_monthly_data
    (1..12).map do |month|
      {
        month: month,
        revenue: 0,
        procurement_cost: 0,
        shipping_cost: 0,
        payment_fees: 0,
        expenses: 0
      }
    end
  end

  def aggregate_orders(orders, monthly_data)
    orders.each do |order|
      month_index = order.sale_date.month - 1
      data = monthly_data[month_index]

      data[:revenue] += order.sales.total_amount
      data[:procurement_cost] += order.procurement.total_cost
      data[:shipping_cost] += order.shipment.cost
      data[:payment_fees] += order.payment_fees.total_amount
    end
  end

  def calculate_metrics(monthly_data)
    monthly_data.each do |data|
      data[:expenses] = data[:shipping_cost] + data[:payment_fees]
      data[:gross_profit] = data[:revenue] - data[:procurement_cost]
      data[:contribution_margin] = data[:gross_profit] - data[:expenses]
      data[:contribution_margin_rate] = calculate_percentage(data[:contribution_margin], data[:revenue])
    end
  end

  def calculate_percentage(value, total)
    return 0 if total.zero?
    (value.to_f / total * 100).round(1)
  end

  def calculate_revenue
    @order.sales.sum(:order_net_amount)
  end

  def calculate_payment_fees
    @order.payment_fees.sum(:fee_amount)
  end

  def calculate_shipping_cost
    @order.shipment&.customer_international_shipping || 0
  end

  def calculate_procurement_cost
    procurement = @order.procurement
    return 0 unless procurement

    [
      procurement.purchase_price,
      procurement.forwarding_fee,
      procurement.handling_fee,
      procurement.option_fee
    ].compact.sum
  end
end
