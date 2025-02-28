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
