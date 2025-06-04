module ExchangeRateConcern
  extend ActiveSupport::Concern

  # 為替レートの定数（デフォルト値）
  # 環境変数から取得するか、デフォルト値を使用
  USD_TO_JPY_RATE = ENV.fetch("USD_TO_JPY_RATE", 150.0).to_f

  # USD → JPYの変換メソッド（月別レート対応）
  def convert_usd_to_jpy(usd_amount, user: nil, year: nil, month: nil)
    return 0 if usd_amount.nil?
    
    rate = if user && year && month
      ExchangeRate.rate_for(user, year, month)
    else
      USD_TO_JPY_RATE
    end
    
    (usd_amount.abs * rate).round(0)
  end
end
