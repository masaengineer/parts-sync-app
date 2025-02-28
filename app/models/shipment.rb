# == Schema Information
#
# Table name: shipments
#
#  id                              :bigint           not null, primary key
#  customer_international_shipping :decimal(, )
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  order_id                        :bigint
#  tracking_number                 :string
#  currency_code                   :string
#
# Indexes
#
#  index_shipments_on_order_id  (order_id)
#
class Shipment < ApplicationRecord
  belongs_to :order
  belongs_to :currency, optional: true

  def self.ransackable_attributes(auth_object = nil)
    %w[
      tracking_number
      customer_international_shipping
      created_at
      updated_at
    ]
  end
end
