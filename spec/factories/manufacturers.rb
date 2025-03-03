FactoryBot.define do
  factory :manufacturer do
    sequence(:name) { |n| Manufacturer.names.keys.sample }
  end
end
