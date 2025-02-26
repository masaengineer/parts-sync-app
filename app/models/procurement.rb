# == Schema Information
#
# Table name: procurements
#
#  id             :bigint           not null, primary key
#  purchase_price :decimal(, )
#  forwarding_fee :decimal(, )
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  handling_fee   :decimal(10, 2)
#  order_id       :bigint           not null
#  option_fee     :decimal(, )
#
# Indexes
#
#  index_procurements_on_order_id  (order_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
class Procurement < ApplicationRecord
  belongs_to :order

  validates :purchase_price, presence: true
  validates :order_id, presence: true

  # 仕入れに関連する全ての費用の合計を計算
  def total_cost
    [ purchase_price, forwarding_fee, option_fee, handling_fee ].compact.sum
  end
end
