class Shipment < ApplicationRecord
  belongs_to :order
  belongs_to :currency, optional: true

  # トラッキング番号でレコードを検索するスコープ
  scope :by_tracking_number, ->(tracking_number) { where(tracking_number: tracking_number) }

  # shipmentの通貨が設定されていない場合はJPYを自動的に設定する
  before_validation :set_default_currency, if: -> { currency_id.nil? }

  def self.ransackable_attributes(auth_object = nil)
    %w[
      tracking_number
      customer_international_shipping
      created_at
      updated_at
    ]
  end

  private

  def set_default_currency
    self.currency = Currency.find_by(code: "JPY")
  end
end
