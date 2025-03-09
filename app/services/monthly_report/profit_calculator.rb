module MonthlyReport
  class ProfitCalculator
    attr_reader :revenue_calculator, :cost_calculator, :expense_calculator

    def initialize(revenue_calculator, cost_calculator, expense_calculator)
      @revenue_calculator = revenue_calculator
      @cost_calculator = cost_calculator
      @expense_calculator = expense_calculator
    end

    # 粗利益の計算
    def calculate_gross_profit
      revenue_calculator.calculate - cost_calculator.calculate
    end

    # 経費の計算
    def calculate_expenses
      expense_calculator.calculate_expenses
    end

    # 限界利益の計算（粗利 - 販管費）
    def calculate_contribution_margin
      gross_profit = calculate_gross_profit
      expenses = expense_calculator.calculate_expenses

      # 月指定がない場合は全期間の経費を使用
      if expenses.zero? && expense_calculator.year.nil? && expense_calculator.month.nil?
        expenses = expense_calculator.calculate_total_expenses
      end

      gross_profit - expenses
    end

    # 限界利益率の計算（限界利益 / 売上高 * 100）
    def calculate_contribution_margin_rate
      revenue = revenue_calculator.calculate
      return 0 if revenue.zero?

      contribution_margin = calculate_contribution_margin
      ((contribution_margin.to_f / revenue) * 100).round
    end
  end
end
