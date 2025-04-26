module MonthlyReport
  class CostCalculator
    include ExchangeRateConcern

    attr_reader :user, :date_range

    def initialize(user, date_range)
      @user = user
      @date_range = date_range
    end

    def calculate
      orders = orders_for_period

      costs_by_order = {}

      orders.each do |order|
        procurement_cost = calculate_procurement_cost_with_currency(order)
        shipping_cost = calculate_shipping_cost_with_currency(order)
        payment_fee_total = calculate_payment_fee_with_currency(order)

        costs_by_order[order.id] = procurement_cost + shipping_cost + payment_fee_total
      end

      costs_by_order.values.sum.round(0)
    end

    private

    def calculate_procurement_cost_with_currency(order)
      return 0 unless order.procurement&.total_cost

      cost = order.procurement.total_cost.to_f

      order_currency = order.currency&.code || "JPY"
      procurement_currency = "JPY"

      if procurement_currency == order_currency
        cost
      else
        convert_to_jpy_by_currency(cost, procurement_currency, order.sale)
      end
    end

    def calculate_shipping_cost_with_currency(order)
      return 0 unless order.shipment&.customer_international_shipping

      cost = order.shipment.customer_international_shipping.to_f

      currency_code = if order.shipment.currency
                        order.shipment.currency.code
                      else
                        "JPY"
                      end
      if currency_code == "JPY"
        cost
      else
        convert_to_jpy_by_currency(cost, currency_code, order.sale)
      end
    end

    def calculate_payment_fee_with_currency(order)
      return 0 if order.payment_fees.empty?

      fee_amount = order.payment_fees.to_a.sum { |fee| fee.fee_amount.to_f || 0 }

      order_currency = order.currency&.code

      if order_currency == "JPY" || order_currency.nil?
        fee_amount
      else
        convert_to_jpy_by_currency(fee_amount, order_currency, order.sale)
      end
    end

    def convert_to_jpy_by_currency(amount, currency_code, sale = nil)
      case currency_code
      when "JPY"
        amount
      when "USD"
        amount * USD_TO_JPY_RATE
      else
        if sale && sale.to_usd_rate
          (amount * sale.to_usd_rate) * USD_TO_JPY_RATE
        else
          amount * USD_TO_JPY_RATE
        end
      end.round(0)
    end

    def orders_for_period
      user.orders
        .where(sale_date: @date_range)
        .includes(
          :procurement,
          { shipment: :currency },
          { payment_fees: [] },
          :currency,
          :sale
        )
    end
  end
end
