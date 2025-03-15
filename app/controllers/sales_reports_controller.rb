class SalesReportsController < ApplicationController
  def index
    # 日付範囲のプリセットを処理
    process_date_preset if params[:date_preset].present?
    
    @q = current_user.orders.ransack(params[:q])

    if params[:sort_by].present?
      current_sort_column = session[:sort_by]
      current_sort_direction = session[:sort_direction]

      if current_sort_column == params[:sort_by]
        if current_sort_direction.nil?
          session[:sort_by] = params[:sort_by]
          session[:sort_direction] = "asc"
        elsif current_sort_direction == "asc"
          session[:sort_by] = params[:sort_by]
          session[:sort_direction] = "desc"
        else
          session[:sort_by] = nil
          session[:sort_direction] = nil
        end
      else
        session[:sort_by] = params[:sort_by]
        session[:sort_direction] = "asc"
      end
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end

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

    if session[:sort_by].present?
      sort_direction = session[:sort_direction] == "desc" ? -1 : 1

      all_orders_data.sort_by! do |data|
        value = case session[:sort_by]
        when "sale_date"
                  # 販売日
                  data[:sale_date] || Time.current
        when "revenue"
                  # USD基準の売上
                  data[:revenue].to_f
        when "profit"
                  # 円建ての利益
                  data[:profit].to_f
        when "profit_rate"
                  # 利益率
                  data[:profit_rate].to_f
        else
                  0
        end

        if session[:sort_by] == "sale_date"
          # 日付は特別な処理（昇順/降順）
          sort_direction == -1 ? value.to_time.to_i * -1 : value.to_time.to_i
        else
          # 数値は乗算でソート
          value * sort_direction
        end
      end
    end

    @orders_data_paginated = Kaminari.paginate_array(all_orders_data)
                                    .page(params[:page])
                                    .per(@per_page)

    @orders_data = @orders_data_paginated

    @orders = @orders_data_paginated
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
    # カスタム以外の場合は日付範囲を計算してパラメータに設定
    return if params[:date_preset] == 'custom'
    
    # DateRangeCalculatorを使用して日付範囲を計算
    today = Date.current
    start_date, end_date = case params[:date_preset]
    when 'last_90_days'
      [today - 90.days, today]
    when 'today'
      [today, today]
    when 'yesterday'
      yesterday = today - 1.day
      [yesterday, yesterday]
    when 'this_week'
      [today.beginning_of_week, today]
    when 'last_week'
      last_week_start = today - 1.week
      [last_week_start.beginning_of_week, last_week_start.end_of_week]
    when 'this_month'
      [today.beginning_of_month, today]
    when 'last_month'
      last_month = today - 1.month
      [last_month.beginning_of_month, last_month.end_of_month]
    when 'this_year'
      [today.beginning_of_year, today]
    when 'last_year'
      last_year = today - 1.year
      [last_year.beginning_of_year, last_year.end_of_year]
    else
      return
    end
    
    # パラメータに計算した日付範囲を設定
    params[:q] ||= {}
    params[:q][:sale_date_gteq] = start_date.to_s
    params[:q][:sale_date_lteq] = end_date.to_s
  end
end
