class SellerSku < ApplicationRecord
  has_many :order_lines
  has_many :sku_mappings
  has_many :manufacturer_skus, through: :sku_mappings

  validates :sku_code, presence: true, uniqueness: true
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id sku_code updated_at]
  end
end
