module SalesReportsHelper
  def table_columns
    [
      { key: :sale_date },
      { key: :order_number, class: "whitespace-nowrap" },
      { key: :sku, class: "max-w-[200px] truncate" },
      { key: :product_name, class: "max-w-[200px] truncate" },
      { key: :revenue, class: "text-right" },
      { key: :fee, header_class: "text-right", cell_class: "text-right text-error" },
      { key: :shipping_cost, header_class: "text-right", cell_class: "text-right text-error" },
      { key: :procurement_cost, header_class: "text-right", cell_class: "text-right text-error" },
      { key: :other_cost, header_class: "text-right", cell_class: "text-right text-error" },
      { key: :quantity, class: "text-right font-medium" },
      { key: :profit, class: "text-right font-bold text-success" },
      { key: :profit_rate, class: "text-right font-medium" },
      { key: :tracking_number, class: "whitespace-nowrap font-medium" }
    ]
  end

  def render_cell_value(data, column)
    case column[:key]
    when :sale_date
      l(data[:sale_date], format: :default) if data[:sale_date]
    when :order_number
      data[:order].order_number
    when :sku
      content_tag(:span, data[:sku_codes], title: data[:sku_codes])
    when :product_name
      content_tag(:span, data[:product_names], title: data[:product_names])
    when :revenue
      format_currency(data[:revenue], data[:order].currency)
    when :fee
      format_currency(data[:payment_fees], data[:order].currency)
    when :shipping_cost
      # 送料は通常、配送先の通貨で表示
      shipment_currency = data[:order].shipment&.currency || data[:order].currency
      format_currency(data[:shipping_cost], shipment_currency)
    when :procurement_cost
      # 調達コストは通常、日本円で表示
      jpy_currency = Currency.find_by(code: "JPY")
      format_currency(data[:procurement_cost], jpy_currency)
    when :other_cost
      # その他コストも通常、日本円で表示
      jpy_currency = Currency.find_by(code: "JPY")
      format_currency(data[:other_costs], jpy_currency)
    when :quantity
      data[:quantity]
    when :profit
      # 利益は日本円で表示
      jpy_currency = Currency.find_by(code: "JPY")
      format_currency(data[:profit], jpy_currency)
    when :profit_rate
      "#{number_with_precision(data[:profit_rate], precision: 1)}%"
    when :tracking_number
      data[:tracking_number]
    end
  end

  # カラムのクラスを取得
  def get_column_class(column, type = :cell)
    return column[:class] if column[:class]
    type == :header ? column[:header_class] : column[:cell_class]
  end

  private

  # 通貨に応じた金額フォーマットを行う
  # @param amount [Numeric] 金額
  # @param currency [Currency] 通貨オブジェクト
  # @return [String] フォーマットされた金額
  def format_currency(amount, currency)
    return "" if amount.nil?

    # 通貨が指定されていない場合はデフォルトでドル表示
    if currency.nil?
      return number_to_currency(amount, unit: "$", precision: 2, format: "%u%n")
    end

    # 通貨コードに応じて精度を変更
    precision = currency.code == "JPY" ? 0 : 2

    # 通貨シンボルと金額を表示
    number_to_currency(
      amount,
      unit: currency.symbol,
      precision: precision,
      format: "%u%n"
    )
  end
end
