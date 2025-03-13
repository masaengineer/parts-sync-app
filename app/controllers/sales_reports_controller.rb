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
                    seller_sku: [:manufacturer_skus, :price_adjustments]
                  }
                )
                .page(params[:page])
                .per(@per_page)

    # SalesReport::Serviceを用いて計算を行う
    @orders_data = @orders.map do |order|
      SalesReport::Service.new(order).calculate
    end
  end

  def show
    # 必要な関連データを事前に読み込み
    @order = current_user.orders.includes(
      :sales,
      :shipment,
      :payment_fees,
      :procurement,
      order_lines: {
        seller_sku: [:manufacturer_skus, :price_adjustments]
      }
    ).find(params[:id])
  end
end
