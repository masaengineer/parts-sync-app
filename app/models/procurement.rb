class Procurement < ApplicationRecord
  belongs_to :order

  validates :purchase_price, presence: true
  validates :order_id, presence: true

  def total_cost
    [ purchase_price, forwarding_fee, handling_fee ].compact.sum
  end
end
