# frozen_string_literal: true

FactoryBot.define do
  factory :shipment do
    order
    tracking_number { SecureRandom.hex(8).upcase }
    customer_international_shipping { rand(1000..5000) }
  end
end
