class Procurement < ApplicationRecord
  belongs_to :order

  validates :purchase_price, presence: true
  validates :order_id, presence: true

  # 仕入れに関連する全ての費用の合計を計算
  def total_cost
    [ purchase_price, forwarding_fee, handling_fee ].compact.sum
  end
end
