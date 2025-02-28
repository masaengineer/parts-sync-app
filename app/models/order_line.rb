# == Schema Information
#
# Table name: order_lines
#
#  id             :bigint           not null, primary key
#  seller_sku_id  :bigint           not null
#  quantity       :integer
#  unit_price     :decimal(, )
#  line_item_id   :integer
#  line_item_name :string
#  order_id       :bigint           not null
#  currency_code  :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
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
