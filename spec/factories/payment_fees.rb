# frozen_string_literal: true

FactoryBot.define do
  factory :payment_fee do
    order
    fee_amount { rand(100..10000) }
    fee_category { 'final_value_fee' }
    transaction_type { 'sale' }
  end
end
