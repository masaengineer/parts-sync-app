class Currency < ApplicationRecord
  # 通貨コードのenum定義
  enum code: {
    usd: "USD", # 米ドル
    jpy: "JPY", # 日本円
    eur: "EUR", # ユーロ
    gbp: "GBP", # 英ポンド
    cad: "CAD", # カナダドル
    aud: "AUD"  # オーストラリアドル
  }, _prefix: true, _suffix: :code

  # 関連付け
  has_many :orders

  # バリデーション
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :symbol, presence: true

  # 検索可能な属性
  def self.ransackable_attributes(auth_object = nil)
    %w[code name symbol active created_at updated_at]
  end

  # 検索可能な関連付け
  def self.ransackable_associations(auth_object = nil)
    %w[orders sales order_lines payment_fees shipments]
  end
end
