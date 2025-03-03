# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    code { "USD" }
    name { "米ドル" }
    symbol { "$" }

    trait :usd do
      code { "USD" }
      name { "米ドル" }
      symbol { "$" }
    end

    trait :jpy do
      code { "JPY" }
      name { "日本円" }
      symbol { "¥" }
    end

    trait :eur do
      code { "EUR" }
      name { "ユーロ" }
      symbol { "€" }
    end

    trait :gbp do
      code { "GBP" }
      name { "英ポンド" }
      symbol { "£" }
    end

    trait :cad do
      code { "CAD" }
      name { "カナダドル" }
      symbol { "C$" }
    end

    trait :aud do
      code { "AUD" }
      name { "オーストラリアドル" }
      symbol { "A$" }
    end
  end
end
