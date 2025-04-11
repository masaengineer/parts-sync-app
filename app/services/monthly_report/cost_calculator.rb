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

      Rails.logger.debug "==== 原価計算のデバッグ情報 ===="
      Rails.logger.debug "対象期間: #{@date_range}"
      Rails.logger.debug "注文数: #{orders.size}"

      total_cost = orders.sum do |order|
        procurement_cost = calculate_procurement_cost_with_currency(order)
        shipping_cost = calculate_shipping_cost_with_currency(order)
        payment_fee_total = calculate_payment_fee_with_currency(order)

        cost_total = procurement_cost + shipping_cost + payment_fee_total

        Rails.logger.debug "注文ID: #{order.id}, 注文番号: #{order.order_number}, 通貨: #{order.currency&.code}"
        Rails.logger.debug "  仕入れコスト（円換算）: #{procurement_cost}"
        Rails.logger.debug "  送料（円換算）: #{shipping_cost}"
        Rails.logger.debug "  決済手数料（円換算）: #{payment_fee_total}"
        Rails.logger.debug "  原価合計: #{cost_total}"

        cost_total
      end.round(0)

      Rails.logger.debug "原価合計: #{total_cost}"
      Rails.logger.debug "=============================="

      total_cost
    end

    private

    def calculate_procurement_cost_with_currency(order)
      return 0 unless order.procurement&.total_cost

      cost = order.procurement.total_cost.to_f

      convert_to_jpy_by_currency(cost, order.currency&.code, order.sale)
    end

    def calculate_shipping_cost_with_currency(order)
      return 0 unless order.shipment&.customer_international_shipping

      cost = order.shipment.customer_international_shipping.to_f

      currency_code = if order.shipment.currency
                        order.shipment.currency.code
      else
                        order.currency&.code
      end

      convert_to_jpy_by_currency(cost, currency_code, order.sale)
    end

    def calculate_payment_fee_with_currency(order)
      return 0 if order.payment_fees.empty?

      fee_amount = order.payment_fees.sum(:fee_amount).to_f

      convert_to_jpy_by_currency(fee_amount, order.currency&.code, order.sale)
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
        .includes(:procurement, { shipment: :currency }, :payment_fees, :currency, :sale)
    end
  end
end
