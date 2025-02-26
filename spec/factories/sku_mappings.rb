FactoryBot.define do
  factory :sku_mapping do
    association :seller_sku
    association :manufacturer_sku
  end
end
