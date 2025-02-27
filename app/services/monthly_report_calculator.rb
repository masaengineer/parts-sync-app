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

    # 通貨ごとに金額を集計
    usd_sales = orders.where(currency: 'USD').sum("sales.order_net_amount") || 0
    eur_sales = orders.where(currency: 'EUR').sum("sales.order_net_amount") || 0
    gbp_sales = orders.where(currency: 'GBP').sum("sales.order_net_amount") || 0

    # 外貨を円に変換して合算
    jpy_total = CurrencyConverter.to_jpy(usd_sales, currency: 'USD') +
                CurrencyConverter.to_jpy(eur_sales, currency: 'EUR') +
                CurrencyConverter.to_jpy(gbp_sales, currency: 'GBP')
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
