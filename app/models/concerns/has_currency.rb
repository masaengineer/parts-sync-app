module HasCurrency
  extend ActiveSupport::Concern
  
  included do
    # 通貨関連のスコープ定義
    scope :with_usd, -> { joins(:currency).where(currencies: { code: 'USD' }) }
    scope :with_jpy, -> { joins(:currency).where(currencies: { code: 'JPY' }) }
    scope :with_eur, -> { joins(:currency).where(currencies: { code: 'EUR' }) }
    scope :with_gbp, -> { joins(:currency).where(currencies: { code: 'GBP' }) }
    scope :with_currency, ->(currency_code) { joins(:currency).where(currencies: { code: currency_code }) }
  end
  
  # 金額フィールドを通貨記号付きでフォーマットするヘルパーメソッド
  def formatted_amount(field_name)
    return nil unless self[field_name].present?
    return self[field_name].to_s unless currency.present?
    
    currency.format_amount(self[field_name])
  end
  
  # 通貨が設定されているかをチェック
  def has_currency?
    currency.present?
  end
  
  # 特定の通貨かどうかをチェック
  def has_currency?(code)
    currency.present? && currency.code == code
  end
  
  # 通貨を設定するヘルパーメソッド
  def set_currency(currency_code)
    return false if currency_code.blank?
    
    currency_obj = Currency.find_by(code: currency_code) || 
                   Currency.find_or_create_by_code(currency_code)
    
    update(currency: currency_obj)
  end
end
