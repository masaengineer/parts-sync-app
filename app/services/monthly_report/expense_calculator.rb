module MonthlyReport
  class ExpenseCalculator
    attr_reader :start_date, :end_date, :year, :month

    def initialize(start_date, end_date, year = nil, month = nil)
      @start_date = start_date
      @end_date = end_date
      @year = year
      @month = month
    end

    # 月の販管費を計算
    def calculate_expenses
      return 0 unless @year && @month
      Expense.where(year: @year, month: @month).sum(:amount).round(0)
    end

    # 期間全体の販管費を計算
    def calculate_total_expenses
      # 月ごとの期間を取得
      date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
      period_months = date_calculator.months_between

      # 一度のクエリで対象期間の全ての費用を取得
      expenses = Expense.where(
        "(year > ? OR (year = ? AND month >= ?)) AND (year < ? OR (year = ? AND month <= ?))",
        @start_date.year, @start_date.year, @start_date.month,
        @end_date.year, @end_date.year, @end_date.month
      )

      # 合計を計算
      expenses.sum(:amount).round(0)
    end
  end
end
