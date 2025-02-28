class Currency < ApplicationRecord
  # 通貨コードのenum定義
  enum code: {
    usd: 'USD', # 米ドル
    jpy: 'JPY', # 日本円
    eur: 'EUR', # ユーロ
    gbp: 'GBP', # 英ポンド
    cad: 'CAD', # カナダドル
    aud: 'AUD'  # オーストラリアドル
  }, _prefix: true, _suffix: :code
  
  # 関連付け
  has_many :orders
  has_many :sales
  has_many :order_lines
  has_many :payment_fees
  has_many :shipments
  
  # バリデーション
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :symbol, presence: true
  
  # 通貨記号と金額を組み合わせて表示するヘルパーメソッド
  def format_amount(amount)
    return nil if amount.nil?
    "#{symbol}#{amount}"
  end
  
  # 通貨コードから通貨を検索または作成するヘルパーメソッド
  def self.find_or_create_by_code(code, name = nil, symbol = nil)
    currency = find_by(code: code)
    return currency if currency.present?
    
    # デフォルト値の設定
    default_values = {
      'USD' => { name: 'US Dollar', symbol: '$' },
      'JPY' => { name: 'Japanese Yen', symbol: '¥' },
      'EUR' => { name: 'Euro', symbol: '€' },
      'GBP' => { name: 'British Pound', symbol: '£' },
      'CAD' => { name: 'Canadian Dollar', symbol: 'C$' },
      'AUD' => { name: 'Australian Dollar', symbol: 'A$' }
    }
    
    attributes = default_values[code] || { name: name || code, symbol: symbol || code[0] }
    create!(code: code, name: attributes[:name], symbol: attributes[:symbol], active: true)
  end
  
  # 検索可能な属性
  def self.ransackable_attributes(auth_object = nil)
    %w[code name symbol active created_at updated_at]
  end
  
  # 検索可能な関連付け
  def self.ransackable_associations(auth_object = nil)
    %w[orders sales order_lines payment_fees shipments]
  end
  
  # 通貨コードをenum値に変換するメソッド
  def code_enum
    code_before_type_cast
  end
  
  # 通貨コードをenum値から文字列に変換するメソッド
  def code_string
    code_before_type_cast.to_s
  end
end
