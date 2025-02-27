# app/services/currency_converter.rb

class CurrencyConverter
  # 為替レートの定数
  # 環境変数から取得するか、デフォルト値を使用
  DEFAULT_RATES = {
    "USD" => ENV.fetch("USD_TO_JPY_RATE", 135.0).to_f,
    "EUR" => ENV.fetch("EUR_TO_JPY_RATE", 145.0).to_f,
    "GBP" => ENV.fetch("GBP_TO_JPY_RATE", 170.0).to_f
  }

  # デフォルトでは現在のレートを使用
  def self.to_jpy(amount, currency: "USD", rate: nil, date: nil)
    return 0 if amount.nil? || amount.zero?

    # レートが指定されていない場合、DBやAPIから取得
    exchange_rate = rate || fetch_exchange_rate(currency, date)

    # 外貨を円に変換して返す
    (amount * exchange_rate).round
  end

  # 複数の金額を一括で円に変換
  def self.bulk_to_jpy(amounts, currency: "USD", rate: nil, date: nil)
    exchange_rate = rate || fetch_exchange_rate(currency, date)

    amounts.map { |amount| (amount * exchange_rate).round }
  end

  private

  # 為替レートを取得するメソッド
  # 実際の実装では、DBやAPIから日付に対応するレートを取得する
  def self.fetch_exchange_rate(currency, date = nil)
    date ||= Date.current

    # 現実のプロジェクトでは、以下のようなロジックになる
    # ExchangeRate.find_by(currency: currency, date: date)&.rate ||
    #   fetch_rate_from_api(currency, date)

    # 環境変数から設定されたレートを使用するか、デフォルト値を使用
    case currency.upcase
    when "USD"
      DEFAULT_RATES["USD"]
    when "EUR"
      DEFAULT_RATES["EUR"]
    when "GBP"
      DEFAULT_RATES["GBP"]
    else
      1.0    # その他の通貨はそのまま（円と仮定）
    end
  end

  # APIから為替レートを取得する場合のメソッド（実装例）
  def self.fetch_rate_from_api(currency, date)
    # 外部APIを呼び出してレートを取得するロジック
    # ExchangeRateClient.get_rate(currency, date)

    # デモ用に固定値を返す
    DEFAULT_RATES[currency.upcase] || 135.0
  end
end
