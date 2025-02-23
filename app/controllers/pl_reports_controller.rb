class PlReportsController < ApplicationController
  def index
    @selected_year = (params[:year] || Time.current.year).to_i
    @available_years = (2020..Time.current.year).to_a.reverse

    year = @selected_year

    # 指定年の注文を取得
    orders = Order.where("extract(year from sale_date) = ?", year)
                  .includes(
                    :sales,
                    :shipment,
                    :payment_fees,
                    :procurement,
                    order_lines: { seller_sku: :manufacturer_skus }
                  )

    # 月別に集計するための初期化（1～12月分のハッシュを用意）
    @monthly_data = (1..12).map do |month|
      {
        month: month,
        revenue: 0,
        procurement_cost: 0,
        shipping_cost: 0,
        payment_fees: 0,
        expenses: 0
      }
    end

    # 各OrderをReportCalculatorで計算して月別に集計
    orders.each do |order|
      next unless order.sale_date.present?

      # 売上日が何月か
      month = order.sale_date.month
      data = @monthly_data[month - 1]

      # サービスクラスで計算
      calc_result = ReportCalculator.new(order).calculate

      # 売上(revenue)はcalc_result[:revenue](USD)を円換算
      revenue_jpy = convert_usd_to_jpy(calc_result[:revenue])
      data[:revenue] += revenue_jpy

      # 手数料も同様にドルを円換算
      payment_fees_jpy = convert_usd_to_jpy(calc_result[:payment_fees])
      data[:payment_fees] += payment_fees_jpy

      # 送料(円)
      data[:shipping_cost] += calc_result[:shipping_cost]

      # 原価(円)
      data[:procurement_cost] += calc_result[:procurement_cost]
    end

    # 販管費(Expensesテーブル)を年・月別に集計
    expenses_by_month = Expense.where(year: year).group(:month).sum(:amount)
    @monthly_data.each do |data|
      m = data[:month]
      data[:expenses] = expenses_by_month[m].to_f if expenses_by_month.key?(m)
    end

    # 月別計算
    @monthly_data.each do |data|
      revenue = data[:revenue]
      procurement_cost = data[:procurement_cost]
      payment_fees = data[:payment_fees]
      shipping_cost = data[:shipping_cost]
      expenses = data[:expenses]

      # 粗利 = 売上 - 原価
      gross_profit = revenue - procurement_cost

      # 限界利益 = 売上高 - (原価 + 送料 + 手数料)
      contribution_margin = revenue - (procurement_cost + shipping_cost + payment_fees)

      # 限界利益率 = 限界利益 / 売上高 * 100
      contribution_margin_rate = revenue.zero? ? 0 : (contribution_margin / revenue * 100)

      data[:gross_profit] = gross_profit
      data[:contribution_margin] = contribution_margin
      data[:contribution_margin_rate] = contribution_margin_rate
    end
  end
end
