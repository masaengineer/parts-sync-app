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
      # 送料は常にJPYとして扱う
      format_jpy_currency(data[:shipping_cost])
    when :procurement_cost
      # 仕入原価は常にJPYとして扱う
      format_jpy_currency(data[:procurement_cost])
    when :other_cost
      # その他原価は常にJPYとして扱う
      format_jpy_currency(data[:other_costs])
    when :quantity
      data[:quantity]
    when :profit
      # 利益は常にJPYとして扱う
      format_jpy_currency(data[:profit])
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

  # 検索フォームの入力フィールドを生成するヘルパーメソッド
  def search_form_field(form, field_name, label_text, options = {})
    field_type = options[:field_type] || :search_field
    input_classes = "input input-sm input-bordered w-full focus:input-primary text-base"
    label_classes = "label font-medium text-sm"

    content_tag(:div, class: "form-control w-full") do
      concat form.label(field_name, label_text, class: label_classes)
      concat form.send(field_type, field_name, class: input_classes)
    end
  end

  # 検索フォームのフィールド設定を返すメソッド
  def search_form_fields
    [
      { name: :order_number_cont, label: "注文番号" },
      { name: :shipment_tracking_number_cont, label: "追跡番号" },
      { name: :order_lines_seller_sku_sku_code_cont, label: "SKUコード" },
      { name: :sale_date_gteq, label: "販売日（から）", field_type: :date_field },
      { name: :sale_date_lteq, label: "販売日（まで）", field_type: :date_field }
    ]
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

    # 通貨コードに応じて精度と単位を変更
    if currency.code == "JPY"
      precision = 0
      unit = "¥"
    else
      precision = 2
      unit = currency.symbol || "$"
    end

    # 通貨シンボルと金額を表示
    number_to_currency(
      amount,
      unit: unit,
      precision: precision,
      format: "%u%n"
    )
  end

  # JPY通貨の金額フォーマットを行う
  # @param amount [Numeric] 金額
  # @return [String] フォーマットされた金額
  def format_jpy_currency(amount)
    return "" if amount.nil?

    number_to_currency(amount, unit: "¥", precision: 0, format: "%u%n")
  end
end
