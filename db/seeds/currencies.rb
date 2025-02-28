# 通貨テーブルの初期データ
currencies = [
  { code: 'USD', name: 'US Dollar', symbol: '$' },
  { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
  { code: 'EUR', name: 'Euro', symbol: '€' },
  { code: 'GBP', name: 'British Pound', symbol: '£' },
  { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$' },
  { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' }
]

currencies.each do |currency_data|
  Currency.find_or_create_by(code: currency_data[:code]) do |currency|
    currency.name = currency_data[:name]
    currency.symbol = currency_data[:symbol]
    currency.active = true
  end
end

puts "通貨マスターデータを作成しました (#{Currency.count}件)"

# 既存の注文データに通貨を設定する例
if Order.where(currency_id: nil).exists?
  puts "Orders without currency: #{Order.where(currency_id: nil).count}"
  usd_currency = Currency.find_by(code: 'USD')
  if usd_currency
    Order.where(currency_id: nil).update_all(currency_id: usd_currency.id)
    puts "Set USD currency to #{Order.where(currency_id: usd_currency.id).count} orders"
  end
end

# 既存の販売データに通貨を設定する例
if Sale.where(currency_id: nil).exists?
  puts "Sales without currency: #{Sale.where(currency_id: nil).count}"
  usd_currency = Currency.find_by(code: 'USD')
  if usd_currency
    Sale.where(currency_id: nil).update_all(currency_id: usd_currency.id)
    puts "Set USD currency to #{Sale.where(currency_id: usd_currency.id).count} sales"
  end
end

puts "通貨コードの設定が完了しました"
