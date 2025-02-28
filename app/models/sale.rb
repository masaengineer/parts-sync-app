class Sale < ApplicationRecord
  belongs_to :order
  # currency_idカラムを削除したため、orderから通貨を委譲
  delegate :currency, to: :order

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
    %w[order currency]
  end
end
