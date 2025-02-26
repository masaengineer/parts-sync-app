# frozen_string_literal: true

FactoryBot.define do
  factory :sale do
    association :order
    order_net_amount { 1000 }
    order_gross_amount { 1200 }
  end
end
