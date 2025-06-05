FactoryBot.define do
  factory :exchange_rate do
    year { Date.current.year }
    month { Date.current.month }
    usd_to_jpy_rate { 150.0 }
    association :user
  end
end
