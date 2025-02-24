# frozen_string_literal: true

FactoryBot.define do
  factory :order_line do
    order
    seller_sku
    quantity { rand(1..10) }
    unit_price { rand(100..10000) }
    line_item_id { rand(1000..9999) }
    line_item_name { Faker::Commerce.product_name }
  end
end
