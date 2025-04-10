module MonthlyReport
  class ExpenseCalculator
    attr_reader :start_date, :end_date, :year, :month

    def initialize(start_date, end_date, year = nil, month = nil)
      @start_date = start_date
      @end_date = end_date
      @year = year
      @month = month
    end

    def calculate_expenses
      return 0 unless @year && @month
      Expense.where(year: @year, month: @month).sum(:amount).round(0)
    end

    def calculate_total_expenses
      date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
      period_months = date_calculator.months_between

      expenses = Expense.where(
        "(year > ? OR (year = ? AND month >= ?)) AND (year < ? OR (year = ? AND month <= ?))",
        @start_date.year, @start_date.year, @start_date.month,
        @end_date.year, @end_date.year, @end_date.month
      )

      expenses.sum(:amount).round(0)
    end
  end
end
