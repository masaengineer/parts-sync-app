class SellerSku < ApplicationRecord
  has_many :order_lines
  has_many :sku_mappings
  has_many :manufacturer_skus, through: :sku_mappings
  has_many :price_adjustments, dependent: :destroy

  validates :sku_code, presence: true, uniqueness: true

  scope :by_code, ->(code) { where("sku_code LIKE ?", "%#{code}%") }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id sku_code updated_at item_id]
  end

  def ebay_item_url
    return nil unless item_id.present?
    "https://www.ebay.com/itm/#{item_id}"
  end

  def latest_adjustment_date
    price_adjustments.order(adjustment_date: :desc).first&.adjustment_date
  end
end
