# frozen_string_literal: true

FactoryBot.define do
  factory :procurement do
    association :order
    purchase_price { 800 }
    forwarding_fee { 200 }
    option_fee { 100 }
    handling_fee { 150 }
  end
end
