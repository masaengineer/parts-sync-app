class PriceAdjustmentsController < ApplicationController
  def new
    @price_adjustment = PriceAdjustment.new
    @seller_sku = SellerSku.find_by(id: params[:seller_sku_id])
    @order_id = params[:order_id]

    if @order_id.present?
      order = Order.find_by(id: @order_id)
      @currency = order&.currency
    end

    @currency ||= Currency.find_by(code: "USD")

    if @seller_sku && @seller_sku.order_lines.any? { |line| line.order.user_id == current_user.id }
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to sales_reports_path }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "price-adjustment-form",
            partial: "shared/error",
            locals: { message: t("unauthorized") }
          )
        }
        format.html { redirect_to sales_reports_path, flash: { error: t("unauthorized") } }
      end
    end
  end

  def create
    @price_adjustment = PriceAdjustment.new(price_adjustment_params)
    @success = false
    @message = ""
    @order_id = params[:return_order_id].presence

    @seller_sku = SellerSku.find_by(id: price_adjustment_params[:seller_sku_id])

    if @seller_sku && @seller_sku.order_lines.any? { |line| line.order.user_id == current_user.id }
      if @price_adjustment.save
        @success = true
        @message = t(".success")
        @item_id = @seller_sku.item_id

        # 更新時に最新の調整情報を取得（日付とフォーマット用）
        @affected_orders = Order.joins(order_lines: :seller_sku)
                               .where(order_lines: { seller_skus: { item_id: @item_id } })
                               .where(user_id: current_user.id)
                               .distinct

        # 更新が必要な注文IDの配列を保持
        @affected_order_ids = @affected_orders.pluck(:id)
      else
        @message = t(".error")
      end
    else
      # アクセス権限がない場合
      @message = t("unauthorized")
    end

    respond_to do |format|
      format.html do
        # HTMLリクエストの場合は従来通りリダイレクト
        flash[@success ? :success : :error] = @message

        if @order_id.present?
          redirect_to sales_report_path(@order_id)
        else
          redirect_to sales_reports_path
        end
      end

      format.turbo_stream
    end
  end

  private

  def price_adjustment_params
    params.require(:price_adjustment).permit(:seller_sku_id, :adjustment_date, :adjustment_amount, :notes, :currency_id)
  end
end
