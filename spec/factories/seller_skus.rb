# frozen_string_literal: true

FactoryBot.define do
  factory :seller_sku do
    sequence(:sku_code) { |n| "SKU#{n}" }
  end
end
