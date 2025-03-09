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

      # 各注文の調達コストを合計
      orders.sum do |order|
        order.procurement&.total_cost.to_f
      end.round(0)
    end

    private

    # 期間内の注文を取得
    def orders_for_period
      user.orders
        .where(sale_date: @date_range)
        .includes(:procurement)
    end
  end
end
