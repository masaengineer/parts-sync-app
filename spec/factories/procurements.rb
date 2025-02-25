# frozen_string_literal: true

FactoryBot.define do
  factory :procurement do
    order
    purchase_price { rand(1000..100000) }
    forwarding_fee { rand(500..5000) }
    handling_fee { rand(100..1000) }
    option_fee { rand(0..5000) }
  end
end
