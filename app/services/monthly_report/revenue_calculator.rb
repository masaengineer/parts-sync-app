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
            usd_orders_jpy_amount = calculate_foreign_currency_revenue(currency_orders)
            revenue_data[code_key] = usd_orders_jpy_amount
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
      # 対象は既にJPY通貨の注文データ
      total = 0

      orders.each do |order|
        order_amount = order.sales.sum { |sale| sale.order_gross_amount.to_f }
        total += order_amount
      end

      total.round(0)
    end

    def calculate_foreign_currency_revenue(orders)
      # 対象は外貨建て注文データ
      jpy_total = 0

      orders.each do |order|
        currency_code = order.currency&.code || "USD"

        order.sales.each do |sale|
          next unless sale.order_gross_amount

          amount = sale.order_gross_amount.to_f

          jpy_amount = case currency_code
          when "JPY"
            amount
          when "USD"
            amount * USD_TO_JPY_RATE
          else
            rate = sale.to_usd_rate || 1.0
            (amount * rate) * USD_TO_JPY_RATE
          end

          jpy_total += jpy_amount
        end
      end

      jpy_total.round(0)
    end
  end
end
