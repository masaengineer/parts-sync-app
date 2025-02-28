class Order < ApplicationRecord
  belongs_to :user
  belongs_to :currency, optional: true
  has_many :order_lines, dependent: :destroy
  has_many :payment_fees, dependent: :destroy
  has_one :procurement, dependent: :destroy
  has_many :sales
  has_one :shipment

  validates :order_number, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[
      order_number
      sale_date
      created_at
      updated_at
      user_id
      currency_id
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user currency order_lines payment_fees procurement sales shipment]
  end

  # 注文に関連する仕入れコストの合計を計算
  def total_procurement_cost
    procurement&.total_cost || 0
  end

  # 注文に関連する仕入れコストの合計を計算
  def total_cost
    order_lines.sum(&:cost_price)
  end
end
