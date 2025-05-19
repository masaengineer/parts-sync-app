class SalesReportsController < ApplicationController
  def index
    process_date_preset if params[:date_preset].present?

    @q = current_user.orders.ransack(params[:q])

    update_sort_session if params[:sort_by].present?

    @per_page = (params[:per_page] || 30).to_i

    all_orders = @q.result
                .includes(
                  :sales,
                  :shipment,
                  :payment_fees,
                  :procurement,
                  order_lines: {
                    seller_sku: [ :manufacturer_skus, :price_adjustments ]
                  }
                )

    all_orders_data = all_orders.map do |order|
      SalesReport::Service.new(order).calculate
    end

    all_orders_data = sort_orders_data(all_orders_data) if session[:sort_by].present?

    @orders_data_paginated = Kaminari.paginate_array(all_orders_data)
                                    .page(params[:page])
                                    .per(@per_page)

    @orders_data = @orders_data_paginated

    @orders = @orders_data_paginated

    respond_to do |format|
      format.html
      format.csv do
        csv_data = generate_csv(all_orders_data)
        send_data csv_data, filename: "sales_report_#{Date.current}.csv", type: 'text/csv'
      end
    end
  end

  def show
    @order = current_user.orders.includes(
      :sales,
      :shipment,
      :payment_fees,
      :procurement,
      order_lines: {
        seller_sku: [ :manufacturer_skus, :price_adjustments ]
      }
    ).find(params[:id])
  end

  private

  def process_date_preset
    return if params[:date_preset] == "custom"

    today = Date.current
    start_date, end_date = case params[:date_preset]
    when "last_90_days"
      [ today - 90.days, today ]
    when "today"
      [ today, today ]
    when "yesterday"
      yesterday = today - 1.day
      [ yesterday, yesterday ]
    when "this_week"
      [ today.beginning_of_week, today ]
    when "last_week"
      last_week_start = today - 1.week
      [ last_week_start.beginning_of_week, last_week_start.end_of_week ]
    when "this_month"
      [ today.beginning_of_month, today ]
    when "last_month"
      last_month = today - 1.month
      [ last_month.beginning_of_month, last_month.end_of_month ]
    when "this_year"
      [ today.beginning_of_year, today ]
    when "last_year"
      last_year = today - 1.year
      [ last_year.beginning_of_year, last_year.end_of_year ]
    else
      return
    end

    params[:q] ||= {}
    params[:q][:sale_date_gteq] = start_date.to_s
    params[:q][:sale_date_lteq] = end_date.to_s
  end

  def update_sort_session
    new_sort_column = params[:sort_by]

    if session[:sort_by] != new_sort_column
      # 違う列がクリックされた場合、昇順でソート
      session[:sort_by] = new_sort_column
      session[:sort_direction] = "asc"
    else
      # 同じ列がクリックされた場合、ソート方向を切り替え
      case session[:sort_direction]
      when nil
        session[:sort_direction] = "asc" # nil -> asc
      when "asc"
        session[:sort_direction] = "desc" # asc -> desc
      when "desc"
        session[:sort_by] = nil # desc -> nil (ソート解除)
        session[:sort_direction] = nil
      end
    end
  end

  def sort_orders_data(data_array)
    sort_direction = session[:sort_direction] == "desc" ? -1 : 1

    data_array.sort_by do |data|
      value = case session[:sort_by]
      when "sale_date"
                data[:sale_date] || Time.current
      when "revenue"
                data[:revenue].to_f
      when "profit"
                data[:profit].to_f
      when "profit_rate"
                data[:profit_rate].to_f
      else
                0
      end

      if session[:sort_by] == "sale_date"
        sort_direction == -1 ? value.to_time.to_i * -1 : value.to_time.to_i
      else
        value * sort_direction
      end
    end
  end

  def generate_csv(orders_data)
    require 'csv'
    headers = [
      '注文ID',
      '注文番号',
      '販売日',
      'SKUコード',
      '商品名',
      '売上(元通貨)',
      '売上(円換算)',
      '通貨コード',
      '決済手数料(元通貨)',
      '粗利益(元通貨)',
      '粗利益(円換算)',
      '配送料(円)',
      '仕入コスト(円)',
      'その他コスト(円)',
      '数量',
      '純粗利(円)',
      '利益率(%)',
      'トラッキング番号',
      '為替レート(元通貨→USD)',
      '為替レート(USD→JPY)',
      '転送手数料(円)',
      '取扱手数料(円)'
    ]

    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      orders_data.each do |data|
        order = data[:order]

        # 円換算のデータを計算
        usd_to_jpy_rate = 150.0
        revenue_jpy = data[:revenue] * usd_to_jpy_rate
        net_revenue_usd = data[:revenue] - data[:payment_fees]
        net_revenue_jpy = net_revenue_usd * usd_to_jpy_rate

        # 調達関連の詳細情報
        procurement = order.procurement
        forwarding_fee = procurement ? procurement.forwarding_fee.to_f : 0
        handling_fee = procurement ? procurement.handling_fee.to_f : 0

        csv << [
          order.id,
          order.order_number,
          data[:sale_date],
          data[:sku_codes],
          data[:product_names],
          data[:revenue],
          revenue_jpy,
          order.currency&.code || 'USD',
          data[:payment_fees],
          net_revenue_usd,
          net_revenue_jpy,
          data[:shipping_cost],
          data[:procurement_cost],
          data[:other_costs],
          data[:quantity],
          data[:profit],
          data[:profit_rate],
          data[:tracking_number],
          data[:exchange_rate],
          usd_to_jpy_rate,
          forwarding_fee,
          handling_fee
        ]
      end
    end

    csv_data.encode(Encoding::SHIFT_JIS, invalid: :replace, undef: :replace)
  end
end
