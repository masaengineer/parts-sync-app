module ExpensesHelper
  # 月ボタンのクラスを決定
  def month_button_class(current_month, target_month)
    base_class = "btn btn-sm"
    target_month == current_month ? "#{base_class} btn-primary" : "#{base_class} btn-outline"
  end

  # 経費の合計金額を計算
  def total_expenses_amount(expenses)
    expenses.sum(&:amount)
  end

  # 経費データの存在確認
  def expenses_exist?(expenses)
    expenses.any?
  end

  # 経費金額をフォーマット
  def format_expense_amount(amount)
    number_to_currency(amount, unit: "¥", precision: 0)
  end
end
