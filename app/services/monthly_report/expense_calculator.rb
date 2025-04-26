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
      start_year = @start_date.year
      start_month = @start_date.month
      end_year = @end_date.year
      end_month = @end_date.month

      date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
      period_months = date_calculator.months_between

      month_conditions = period_months.map do |year, month|
        { year: year, month: month }
      end

      expenses = Expense.where(month_conditions)

      expenses.sum(:amount).round(0)
    end
  end
end
