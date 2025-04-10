class Sale < ApplicationRecord
  belongs_to :order
  delegate :currency, to: :order

  def transaction_type
    order_net_amount.negative? ? "REFUND" : "SALE"
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      created_at
      updated_at
      order_id
      order_net_amount
      order_gross_amount
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order]
  end
end
