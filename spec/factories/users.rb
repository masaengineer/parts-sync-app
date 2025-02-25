# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    last_name { Faker::Name.last_name }
    first_name { Faker::Name.first_name }

    # ebay_tokenカラムが存在しないため、一時的にコメントアウト
    # trait :with_ebay_token do
    #   ebay_token { SecureRandom.hex(32) }
    # end

    trait :with_google_oauth do
      provider { 'google_oauth2' }
      uid { SecureRandom.uuid }
      profile_picture_url { Faker::Internet.url }
    end
  end
end
