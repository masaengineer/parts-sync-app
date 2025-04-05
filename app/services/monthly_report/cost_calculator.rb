module MonthlyReport
  class CostCalculator
    attr_reader :user, :date_range

    def initialize(user, date_range)
      @user = user
      @date_range = date_range
    end

    # 原価の計算
    def calculate
      orders = orders_for_period


      orders.sum do |order|
        procurement_cost = order.procurement&.total_cost.to_f
        shipping_cost = order.shipment&.customer_international_shipping.to_f
        payment_fee_total = order.payment_fees&.sum(:fee_amount).to_f
        procurement_cost + shipping_cost + payment_fee_total
      end.round(0)
    end

    private

    # 期間内の注文を取得
    def orders_for_period
      user.orders
        .where(sale_date: @date_range)
        # shipment と payment_fees も eager load する
        .includes(:procurement, :shipment, :payment_fees)
    end
  end
end
