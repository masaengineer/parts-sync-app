class Currency < ApplicationRecord
  enum :code, {
    usd: "USD",
    jpy: "JPY",
    eur: "EUR",
    gbp: "GBP",
    cad: "CAD",
    aud: "AUD"
  }, prefix: true

  has_many :orders

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :symbol, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[code name symbol active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[orders sales order_lines payment_fees shipments]
  end
end
