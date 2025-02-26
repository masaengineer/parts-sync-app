# == Schema Information
#
# Table name: payment_fees
#
#  id           :bigint           not null, primary key
#  order_id     :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  fee_category :string
#  fee_amount   :decimal(, )
#
# Indexes
#
#  index_payment_fees_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
class PaymentFee < ApplicationRecord
  belongs_to :order, foreign_key: :order_id

  validates :fee_amount, presence: true, numericality: true
  validates :fee_category, presence: true

  enum transaction_type: {
    sale: "SALE",
    non_sale_charge: "NON_SALE_CHARGE",
    shipping_label: "SHIPPING_LABEL",
    refund: "REFUND"
  }

  enum fee_category: {
    final_value_fee: "FINAL_VALUE_FEE",
    final_value_fee_fixed_per_order: "FINAL_VALUE_FEE_FIXED_PER_ORDER",
    international_fee: "INTERNATIONAL_FEE",
    insertion_fee: "INSERTION_FEE",
    add_fee: "AD_FEE",
    regulatory_operating_fee: "REGULATORY_OPERATING_FEE",
    undefined: "UNDEFINED"
  }

  scope :by_category, ->(category) { where(fee_category: category) }
end
