# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    order_number { SecureRandom.uuid }
    sale_date { Date.current }
    user

    trait :with_order_lines do
      after(:create) do |order|
        create_list(:order_line, 2, order: order)
      end
    end

    trait :with_payment_fees do
      after(:create) do |order|
        create_list(:payment_fee, 2, order: order)
      end
    end

    trait :with_procurement do
      after(:create) do |order|
        create(:procurement, order: order)
      end
    end

    trait :with_shipment do
      after(:create) do |order|
        create(:shipment, order: order)
      end
    end

    trait :with_sales do
      after(:create) do |order|
        create_list(:sale, 2, order: order)
      end
    end

    trait :complete do
      with_order_lines
      with_payment_fees
      with_procurement
      with_shipment
      with_sales
    end
  end
end
