class MonthlyReportCalculator
  attr_reader :user, :year

  def initialize(user, year)
    @user = user
    @year = year
  end

  # 月次データを計算して返す
  def calculate
    (1..12).map do |month|
      {
        month: month,
        revenue: calculate_revenue(month),
        procurement_cost: calculate_procurement_cost(month),
        gross_profit: calculate_gross_profit(month),
        expenses: calculate_expenses(month),
        contribution_margin: calculate_contribution_margin(month),
        contribution_margin_rate: calculate_contribution_margin_rate(month)
      }
    end
  end

  private

  # 指定した月の開始日と終了日を取得
  def date_range(month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    start_date..end_date
  end

  # 売上高の計算
  def calculate_revenue(month)
    orders = user.orders.where(sale_date: date_range(month))
              .joins(:sales)

    # 通貨ごとの売上高をexchangerateを使って円換算して集計
    jpy_total = 0

    # USD売上（exchangerate = 1.0）
    usd_orders = orders.where(currency: "USD")
    usd_sales = usd_orders.joins(:sales).sum("sales.order_net_amount")
    jpy_total += usd_sales * 135.0 # デフォルトのUSD→JPYレート

    # USD以外の外貨売上（exchangerateを使用）
    non_usd_orders = orders.where.not(currency: "USD")
    non_usd_orders.each do |order|
      # 各注文の売上とexchangerateを取得
      sale = order.sales.first
      next unless sale

      # salesテーブルに保存されたexchangerateを使って計算
      net_amount = sale.order_net_amount || 0
      exchange_rate = sale.exchangerate || 1.0

      # 外貨を円に変換（exchangerateはUSDへの変換率なので、さらにUSD→JPYレートで円に変換）
      jpy_amount = (net_amount * exchange_rate) * 135.0 # USD→JPYレート
      jpy_total += jpy_amount
    end

    jpy_total
  end

  # 原価の計算
  def calculate_procurement_cost(month)
    user.orders.where(sale_date: date_range(month))
        .joins(:procurement)
        .sum("procurements.purchase_price + procurements.forwarding_fee + procurements.option_fee + procurements.handling_fee")
  end

  # 粗利の計算（売上高 - 原価）
  def calculate_gross_profit(month)
    calculate_revenue(month) - calculate_procurement_cost(month)
  end

  # 販管費の計算
  def calculate_expenses(month)
    Expense.where(year: year, month: month).sum(:amount)
  end

  # 限界利益の計算（粗利 - 販管費）
  def calculate_contribution_margin(month)
    calculate_gross_profit(month) - calculate_expenses(month)
  end

  # 限界利益率の計算（限界利益 / 売上高 * 100）
  def calculate_contribution_margin_rate(month)
    revenue = calculate_revenue(month)
    return 0 if revenue.zero?

    contribution_margin = calculate_contribution_margin(month)
    ((contribution_margin / revenue) * 100).round
  end
end
