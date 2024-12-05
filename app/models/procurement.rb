class Procurement < ApplicationRecord
  belongs_to :sku

  validates :purchase_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :domestic_transfer_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :forwarding_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :photo_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sku_id, presence: true
end
