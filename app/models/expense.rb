class Expense < ApplicationRecord
  belongs_to :order, optional: true

  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :item_name, presence: true
  validates :amount, presence: true, numericality: true

  # option_feeカラムへのアクセスを許可
  attribute :option_fee, :decimal
end
