# frozen_string_literal: true

FactoryBot.define do
  factory :shipment do
    association :order
    customer_international_shipping { 2000 }
    sequence(:tracking_number) { |n| "TRK-#{n}" }
  end
end
