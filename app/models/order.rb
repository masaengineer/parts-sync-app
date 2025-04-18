class Order < ApplicationRecord
  belongs_to :user
  belongs_to :currency, optional: true
  has_many :order_lines, dependent: :destroy
  has_many :payment_fees, dependent: :destroy
  has_one :procurement, dependent: :destroy
  has_many :sales
  has_one :shipment
  has_many :skus, through: :order_lines, source: :seller_sku
  has_one :sale, -> { order(created_at: :desc) }, class_name: "Sale"

  validates :order_number, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[
      order_number
      sale_date
      created_at
      updated_at
      user_id
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user sale order_lines skus procurement shipment payment_fees]
  end

  def total_procurement_cost
    procurement&.total_cost || 0
  end

  def total_cost
    order_lines.sum(&:cost_price)
  end

  def ebay_order_url
    "https://www.ebay.com/mesh/ord/details?orderid=#{order_number}"
  end
end
