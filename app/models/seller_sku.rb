class SellerSku < ApplicationRecord
  has_many :order_lines
  has_many :sku_mappings
  has_many :manufacturer_skus, through: :sku_mappings

  validates :sku_code, presence: true, uniqueness: true

  # SKUコードで検索するスコープ
  scope :by_code, ->(code) { where("sku_code LIKE ?", "%#{code}%") }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id sku_code updated_at item_id]
  end
  
  # eBay商品ページのURLを取得
  def ebay_item_url
    return nil unless item_id.present?
    "https://www.ebay.com/itm/#{item_id}"
  end
end
