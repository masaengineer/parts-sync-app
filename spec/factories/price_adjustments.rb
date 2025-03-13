FactoryBot.define do
  factory :price_adjustment do
    seller_sku_id { nil }
    adjustment_date { "2025-03-12 15:34:27" }
    adjustment_amount { "9.99" }
    notes { "MyText" }
  end
end
