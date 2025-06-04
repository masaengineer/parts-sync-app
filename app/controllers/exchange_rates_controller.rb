class ExchangeRatesController < ApplicationController
  before_action :set_exchange_rate, only: [ :edit, :update, :destroy ]

  def index
    @exchange_rates = current_user.exchange_rates.order(year: :desc, month: :desc)
    @grouped_rates = @exchange_rates.group_by(&:year)
  end

  def new
    @exchange_rate = current_user.exchange_rates.build
  end

  def create
    @exchange_rate = current_user.exchange_rates.build(exchange_rate_params)

    if @exchange_rate.save
      redirect_to exchange_rates_path, notice: "為替レートを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exchange_rate.update(exchange_rate_params)
      redirect_to exchange_rates_path, notice: "為替レートを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exchange_rate.destroy
    redirect_to exchange_rates_path, notice: "為替レートを削除しました。"
  end

  private

  def set_exchange_rate
    @exchange_rate = current_user.exchange_rates.find(params[:id])
  end

  def exchange_rate_params
    params.require(:exchange_rate).permit(:year, :month, :usd_to_jpy_rate)
  end
end
