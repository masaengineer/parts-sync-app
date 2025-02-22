# app/controllers/sales_reports_controller.rb

class SalesReportsController < ApplicationController
  def index
    @q = current_user.orders.ransack(params[:q])
    @per_page = (params[:per_page] || 30).to_i
    @orders = @q.result
                .includes(
                  :sales,
                  :shipment,
                  :payment_fees,
                  :procurement,
                  order_lines: {
                    seller_sku: :manufacturer_skus
                  }
                )
                .page(params[:page])
                .per(@per_page)

    # ReportCalculatorを用いて計算を行う
    @orders_data = @orders.map do |order|
      ReportCalculator.new(order).calculate
    end
  end
end
