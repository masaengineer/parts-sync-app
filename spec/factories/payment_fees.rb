# frozen_string_literal: true

FactoryBot.define do
  factory :payment_fee do
    association :order
    fee_category { :final_value_fee }
    fee_amount { 100 }
    transaction_type { :sale }
    sequence(:transaction_id) { |n| "TRANS-#{n}" }
  end

  trait :with_international_fee do
    fee_category { :international_fee }
  end

  trait :with_insertion_fee do
    fee_category { :insertion_fee }
  end

  trait :with_ad_fee do
    fee_category { :add_fee }
  end

  trait :with_non_sale_charge do
    transaction_type { :non_sale_charge }
  end

  trait :with_shipping_label do
    transaction_type { :shipping_label }
  end

  trait :with_refund do
    transaction_type { :refund }
  end
end
