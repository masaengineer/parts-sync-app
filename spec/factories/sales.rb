# frozen_string_literal: true

FactoryBot.define do
  factory :sale do
    order
    order_net_amount { rand(1000..100000) }
    order_gross_amount { order_net_amount * 1.1 }
  end
end
