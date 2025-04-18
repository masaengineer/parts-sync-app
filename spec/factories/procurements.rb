# frozen_string_literal: true

FactoryBot.define do
  factory :procurement do
    order
    purchase_price { 800 }
    forwarding_fee { 200 }
    handling_fee { 150 }
  end
end
