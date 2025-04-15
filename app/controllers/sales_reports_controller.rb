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
end
