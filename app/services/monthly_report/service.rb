module MonthlyReport
  class Service
    attr_reader :user, :start_date, :end_date

    def initialize(user, start_date, end_date = nil)
      @user = user
      @start_date = start_date.is_a?(Date) ? start_date.beginning_of_day : start_date.to_date.beginning_of_day
      end_date ||= start_date.is_a?(Date) ? start_date.end_of_month : start_date.to_date.end_of_month
      @end_date = end_date.is_a?(Date) ? end_date.end_of_day : end_date.to_date.end_of_day
    end

    def calculate_by_month
      date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
      months_list = date_calculator.months_list

      months_list.map do |month_start|
        month_end = month_start.end_of_month
        period_range = month_start.beginning_of_day..month_end.end_of_day

        calculate_period_data(period_range, month_start.year, month_start.month)
      end
    end

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

    def chart_data
      monthly_data = calculate_by_month

      revenues = monthly_data.map { |data| data[:revenue] }

      contribution_margins = monthly_data.map { |data| data[:contribution_margin] }

      labels = monthly_data.map { |data| "#{data[:year]}/#{data[:month]}" }

      {
        labels: labels,
        datasets: [
          {
            label: I18n.t("monthly_reports.metrics.revenue"),
            data: revenues
          },
          {
            label: I18n.t("monthly_reports.metrics.contribution_margin"),
            data: contribution_margins
          }
        ]
      }
    end

    def table_data
      monthly_data = calculate_by_month
      totals = calculate_total

      headers = monthly_data.map { |data| "#{data[:year]}年#{data[:month]}月" }

      metrics = [
        { key: :revenue, format: :currency, values: monthly_data.map { |data| data[:revenue] } },
        { key: :total_cost, format: :currency, values: monthly_data.map { |data| data[:total_cost] } },
        { key: :gross_profit, format: :currency, values: monthly_data.map { |data| data[:gross_profit] } },
        { key: :expenses, format: :currency, values: monthly_data.map { |data| data[:expenses] } },
        { key: :contribution_margin, format: :currency, values: monthly_data.map { |data| data[:contribution_margin] } },
        { key: :contribution_margin_rate, format: :percentage, values: monthly_data.map { |data| data[:contribution_margin_rate] } }
      ]

      {
        headers: headers,
        metrics: metrics,
        totals: totals
      }
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

      cost_result = cost_calculator.calculate

      data = {
        revenue: revenue_calculator.calculate,
        total_cost: cost_result
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
