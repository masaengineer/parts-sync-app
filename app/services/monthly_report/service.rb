module MonthlyReport
  class Service
    attr_reader :user, :start_date, :end_date

    def initialize(user, start_date, end_date = nil)
      @user = user
      @start_date = start_date.is_a?(Date) ? start_date.beginning_of_day : start_date.to_date.beginning_of_day
      end_date ||= start_date.is_a?(Date) ? start_date.end_of_month : start_date.to_date.end_of_month
      @end_date = end_date.is_a?(Date) ? end_date.end_of_day : end_date.to_date.end_of_day
    end

    # 月別にデータを集計
    def calculate_by_month
      date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
      months_list = date_calculator.months_list

      # 各月のデータを計算
      months_list.map do |month_start|
        month_end = month_start.end_of_month
        period_range = month_start.beginning_of_day..month_end.end_of_day

        calculate_period_data(period_range, month_start.year, month_start.month)
      end
    end

    # 期間全体の集計を計算
    def calculate_total
      start_date = @start_date.to_date.beginning_of_day
      end_date = @end_date.to_date.end_of_day
      period_range = start_date..end_date

      expense_calculator = ExpenseCalculator.new(@start_date, @end_date)

      data = calculate_period_data(period_range)
      data.merge!(
        start_date: start_date.to_date,
        end_date: end_date.to_date,
        label: "#{start_date.to_date} 〜 #{end_date.to_date}",
        expenses: expense_calculator.calculate_total_expenses
      )
    end

    # グラフ表示用のデータを生成
    def chart_data
      Formatters::ChartFormatter.new(calculate_by_month).format
    end

    # テーブル表示用のデータを生成
    def table_data
      Formatters::TableFormatter.new(calculate_by_month, calculate_total).format
    end

    private

    def calculate_period_data(period_range, year = nil, month = nil)
      revenue_calculator = RevenueCalculator.new(@user, period_range)
      cost_calculator = CostCalculator.new(@user, period_range)
      profit_calculator = ProfitCalculator.new(
        revenue_calculator,
        cost_calculator,
        ExpenseCalculator.new(@start_date, @end_date, year, month)
      )

      data = {
        revenue: revenue_calculator.calculate,
        procurement_cost: cost_calculator.calculate
      }

      if year && month
        data[:year] = year
        data[:month] = month
        data[:expenses] = profit_calculator.calculate_expenses
      end

      data.merge!(
        gross_profit: profit_calculator.calculate_gross_profit,
        contribution_margin: profit_calculator.calculate_contribution_margin,
        contribution_margin_rate: profit_calculator.calculate_contribution_margin_rate
      )
    end
  end
end
