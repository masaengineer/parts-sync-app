FactoryBot.define do
  factory :expense do
    year { Date.today.year }
    month { Date.today.month }
    sequence(:item_name) { |n| "費用項目#{n}" }
    amount { 5000 }
  end
end
