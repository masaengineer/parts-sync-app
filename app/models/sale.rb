# == Schema Information
#
# Table name: sales
#
#  id                 :bigint           not null, primary key
#  order_id           :bigint           not null
#  order_net_amount   :decimal(, )
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  order_gross_amount :decimal(, )
#  currency_id        :bigint
#
# Indexes
#
#  index_sales_on_order_id  (order_id)
#  index_sales_on_currency_id  (currency_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (currency_id => currencies.id)
#
class Sale < ApplicationRecord
  belongs_to :order
  belongs_to :currency, optional: true

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
