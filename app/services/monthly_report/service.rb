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
      @monthly_data_cache ||= begin
        date_calculator = Common::DateRangeCalculator.new(@start_date, @end_date)
        months_list = date_calculator.months_list
        
        # 事前に1年分の月ごとの日付範囲を作成
        period_ranges = months_list.map do |month_start|
          month_end = month_start.end_of_month
          {
            year: month_start.year,
            month: month_start.month,
            range: month_start.beginning_of_day..month_end.end_of_day
          }
        end
        
        # 各期間のデータを一括で計算
        period_ranges.map do |period|
          calculate_period_data(period[:range], period[:year], period[:month])
        end
      end
    end

    def calculate_total
      @total_data_cache ||= begin
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
      # 必要なすべての計算クラスを初期化
      revenue_calculator = RevenueCalculator.new(@user, period_range)
      cost_calculator = CostCalculator.new(@user, period_range)
      expense_calculator = ExpenseCalculator.new(@start_date, @end_date, year, month)
      profit_calculator = ProfitCalculator.new(
        revenue_calculator,
        cost_calculator,
        expense_calculator
      )

      # 基本データを先に計算
      revenue = revenue_calculator.calculate
      total_cost = cost_calculator.calculate
      expenses = year && month ? expense_calculator.calculate_expenses : 0
      
      # 算出データを計算
      gross_profit = revenue - total_cost
      contribution_margin = gross_profit - expenses
      contribution_margin_rate = revenue.zero? ? 0 : ((contribution_margin.to_f / revenue) * 100).round
      
      # 結果をまとめる
      data = {
        revenue: revenue,
        total_cost: total_cost,
        gross_profit: gross_profit,
        contribution_margin: contribution_margin,
        contribution_margin_rate: contribution_margin_rate
      }
      
      # 月別データの場合は追加情報を含める
      if year && month
        data[:year] = year
        data[:month] = month
        data[:expenses] = expenses
      end
      
      data
    end
  end
end
