module SalesReportsHelper
  include CurrencyFormatter

  # ソートアイコンを取得するメソッド
  def get_sort_icon(column_key)
    if session[:sort_by] == column_key
      session[:sort_direction] == "asc" ? "lucide:arrow-up" : "lucide:arrow-down"
    else
      "lucide:arrow-up-down"
    end
  end

  # SKUコードから商品画像のパスを取得するメソッド
  # eBay商品ページからの取得を試み、画像がない場合はnilを返す

  def get_product_image_path(seller_sku)
    return nil unless seller_sku && seller_sku.item_id.present?

    @image_cache ||= {}
    cache_key = "sku_image_#{seller_sku.id}"

    return @image_cache[cache_key] if @image_cache.key?(cache_key)

    begin
      image_url = Rails.cache.fetch("ebay_image_#{seller_sku.item_id}", expires_in: 1.day) do
        item_url = seller_sku.ebay_item_url
        require "open-uri"
        require "nokogiri"

        html = URI.open(item_url).read
        doc = Nokogiri::HTML(html)

        og_image = doc.at('meta[property="og:image"]')&.attr("content")

        image_element = doc.at("div#mainImgHldr img") ||
                        doc.at("div.ux-image-carousel-item img") ||
                        doc.at("img.img.img500")

        image_url = og_image || image_element&.attr("src")
        image_url
      end

      if image_url.present?
        @image_cache[cache_key] = image_url
        return image_url
      end
    rescue => e
      Rails.logger.error "eBay画像取得エラー: #{e.message}"
    end

    nil
  end

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
      { key: :price_adjusted, class: "text-center" },
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
      format_jpy_currency(data[:shipping_cost])
    when :procurement_cost
      format_jpy_currency(data[:procurement_cost])
    when :other_cost
      format_jpy_currency(data[:other_costs])
    when :quantity
      data[:quantity]
    when :profit
      format_jpy_currency(data[:profit])
    when :profit_rate
      "#{number_with_precision(data[:profit_rate], precision: 1)}%"
    when :price_adjusted
      date = latest_price_adjustment_date(data[:order])
      item_ids = data[:order].order_lines.map { |line| line.seller_sku&.item_id }.compact.uniq

      if date.present? && item_ids.any?
        content_tag(:div, class: "flex justify-center", data: { price_adjusted_cell: item_ids.first }) do
          content_tag(:span, l(date, format: :short), class: "badge badge-primary badge-outline text-xs")
        end
      else
        ""
      end
    when :tracking_number
      data[:tracking_number].presence || ""
    end
  end

  # 注文に紐づく商品の最新の価格調整日を取得
  def latest_price_adjustment_date(order)
    @latest_price_adjustment_dates ||= {}

    order.order_lines.each do |line|
      seller_sku = line.seller_sku
      next unless seller_sku&.item_id.present?

      item_id = seller_sku.item_id

      if !@latest_price_adjustment_dates.key?(item_id)
        latest_adjustment = price_adjustment_for_item_id(item_id)
        @latest_price_adjustment_dates[item_id] = latest_adjustment&.adjustment_date
      end

      return @latest_price_adjustment_dates[item_id] if @latest_price_adjustment_dates[item_id].present?
    end

    nil
  end

  def price_adjustment_for_item_id(item_id)
    @price_adjustments_cache ||= {}

    return @price_adjustments_cache[item_id] if @price_adjustments_cache.key?(item_id)

    @price_adjustments_cache[item_id] = PriceAdjustment.joins(:seller_sku)
                                                    .where(seller_skus: { item_id: item_id })
                                                    .order(adjustment_date: :desc)
                                                    .first
  end

  def get_column_class(column, type = :cell)
    return column[:class] if column[:class]
    type == :header ? column[:header_class] : column[:cell_class]
  end

  def search_form_field(form, field_name, label_text, options = {})
    field_type = options[:field_type] || :search_field
    input_classes = "input input-sm input-bordered w-full focus:input-primary text-base bg-base-100 pl-10"

    # フィールド名からプレースホルダーのキーを生成（例: order_number_cont -> order_number）
    placeholder_key = field_name.to_s.gsub(/_cont$|_gteq$|_lteq$/, "")
    placeholder = t("sales_reports.placeholder.#{placeholder_key}", default: label_text)

    # 各フィールドのアイコンを決定
    icon = case placeholder_key
    when "order_number"
             "lucide:hash"
    when "shipment_tracking_number"
             "lucide:package"
    when "order_lines_seller_sku_sku_code"
             "lucide:tag"
    else
             "lucide:search"
    end

    # data属性があれば適用
    html_options = { class: input_classes, placeholder: placeholder }
    html_options.merge!(data: options[:data]) if options[:data].present?

    content_tag(:div, class: "form-control w-full") do
      input_wrapper = content_tag(:div, class: "relative") do
        icon_wrapper = content_tag(:div, class: "absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none") do
          "<iconify-icon icon=\"#{icon}\" class=\"w-4 h-4 text-gray-500\"></iconify-icon>".html_safe
        end

        input = form.send(field_type, field_name, html_options)

        icon_wrapper + input
      end

      input_wrapper
    end
  end

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

  def format_currency(amount, currency)
    return "" if amount.nil?

    if currency.nil?
      return format_usd(amount)
    end

    case currency.code.upcase
    when "JPY"
      format_jpy(amount)
    when "USD"
      format_usd(amount)
    else
      format_amount(amount, currency.symbol, 2)
    end
  end

  def format_jpy_currency(amount)
    return "" if amount.nil?

    number_to_currency(amount, unit: "¥", precision: 0, format: "%u%n")
  end
end
