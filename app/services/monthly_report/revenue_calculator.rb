module MonthlyReport
  class RevenueCalculator
    include ExchangeRateConcern

    attr_reader :user, :date_range

    def initialize(user, date_range)
      @user = user
      @date_range = date_range
    end

    def calculate
      calculate_by_currency.values.sum
    end

    def calculate_by_currency(currency_codes = nil)
      orders = orders_for_period
      revenue_data = {}

      currencies = if currency_codes
                    codes = Array(currency_codes).map(&:upcase)
                    Currency.where(code: codes)
      else
                    Currency.all
      end

      currencies.each do |currency|
        currency_orders = orders.joins(:currency).where(currencies: { code: currency.code })

        if currency_orders.exists?
          code_key = currency.code.downcase.to_sym

          case currency.code
          when "JPY"
            revenue_data[code_key] = calculate_currency_revenue(currency_orders)
          when "USD"
            usd_amount = calculate_currency_revenue(currency_orders)
            revenue_data[code_key] = (usd_amount * USD_TO_JPY_RATE).round(0)
          else
            revenue_data[code_key] = calculate_foreign_currency_revenue(currency_orders)
          end
        end
      end

      revenue_data
    end

    private

    def orders_for_period
      user.orders
        .where(sale_date: @date_range)
        .includes(:sales, :currency, :procurement)
    end

    def calculate_currency_revenue(orders)
      orders.sum { |order| order.sales.sum(&:order_net_amount).to_f }.round(0)
    end

    def calculate_foreign_currency_revenue(orders)
      jpy_total = 0

      orders.each do |order|
        order.sales.each do |sale|
          next unless sale.order_net_amount

          net_amount = sale.order_net_amount.to_f
          to_usd_rate = sale.to_usd_rate || 1.0

          jpy_amount = (net_amount * to_usd_rate) * USD_TO_JPY_RATE
          jpy_total += jpy_amount
        end
      end

      jpy_total.round(0)
    end
  end
end
