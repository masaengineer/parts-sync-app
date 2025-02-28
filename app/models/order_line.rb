class OrderLine < ApplicationRecord
  belongs_to :seller_sku
  belongs_to :order
  belongs_to :currency, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :line_item_id, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id line_item_id line_item_name order_id quantity seller_sku_id unit_price updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order seller_sku currency] # 検索可能な関連付け
  end
end
