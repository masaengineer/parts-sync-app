FactoryBot.define do
  factory :manufacturer_sku do
    sequence(:sku_code) { |n| "MF-SKU-#{n}" }
    association :manufacturer
  end
end
