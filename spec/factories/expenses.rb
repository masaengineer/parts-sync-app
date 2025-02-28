FactoryBot.define do
  factory :expense do
    year { Time.current.year }
    month { 1 }
    item_name { "営業経費" }
    amount { 20000 }
  end
end
