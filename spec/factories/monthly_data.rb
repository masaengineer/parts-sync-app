FactoryBot.define do
  factory :monthly_data do
    user
    year { Time.current.year }
    month { 1 }
    revenue { 100000 }
    procurement_cost { 50000 }
    expenses { 20000 }

    # 以下の属性は計算により導出される
    # gross_profit = revenue - procurement_cost
    # contribution_margin = gross_profit - expenses
    # contribution_margin_rate = (contribution_margin / revenue * 100).round
  end
end
