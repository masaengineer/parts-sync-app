module CurrencyFormatter
  extend ActiveSupport::Concern

  def format_amount(amount, symbol, precision = 2)
    return "" if amount.nil?
    number_to_currency(amount, unit: symbol, precision: precision, format: "%u%n")
  end

  def format_jpy(amount)
    format_amount(amount, "¥", 0)
  end

  def format_usd(amount)
    format_amount(amount, "$", 2)
  end

  def format_eur(amount)
    format_amount(amount, "€", 2)
  end

  def format_gbp(amount)
    format_amount(amount, "£", 2)
  end
end
