FactoryBot.define do
  factory :expense do
    year { Time.current.year }
    month { 1 }
    item_name { "営業経費" }
    amount { 20000 }

    trait :option_fee do
      expense_type { "option_fee" }
      item_name { "オプション料金" }
      amount { 100 }
      option_fee { 100 }
    end
  end
end
