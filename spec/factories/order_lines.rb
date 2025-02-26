# frozen_string_literal: true

FactoryBot.define do
  factory :order_line do
    association :seller_sku
    association :order
    quantity { 1 }
    unit_price { 1000 }
    line_item_id { 1 }
    line_item_name { "テスト商品" }
  end
end
