class PriceAdjustment < ApplicationRecord
  belongs_to :seller_sku
  belongs_to :currency, optional: true

  validates :seller_sku_id, presence: true
  validates :adjustment_date, presence: true
  validates :adjustment_amount, presence: true

  scope :latest_by_seller_sku, ->(seller_sku_id) {
    where(seller_sku_id: seller_sku_id).order(adjustment_date: :desc).first
  }

  before_validation :set_default_currency

  private

  def set_default_currency
    self.currency ||= Currency.find_by(code: "USD")
  end
end
