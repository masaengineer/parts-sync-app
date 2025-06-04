class ExchangeRate < ApplicationRecord
  belongs_to :user

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2020 }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :usd_to_jpy_rate, presence: true, numericality: { greater_than: 0 }
  validates :year, uniqueness: { scope: [:user_id, :month] }

  scope :for_period, ->(year, month) { where(year: year, month: month) }

  def self.rate_for(user, year, month)
    exchange_rate = find_by(user: user, year: year, month: month)
    exchange_rate&.usd_to_jpy_rate || ENV.fetch("USD_TO_JPY_RATE", 150.0).to_f
  end
end
