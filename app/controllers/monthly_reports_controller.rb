# app/controllers/monthly_reports_controller.rb

class MonthlyReportsController < ApplicationController
  def index
    # 利用可能な年度を取得（ordersテーブルから）
    @available_years = current_user.orders
                        .select(Arel.sql("EXTRACT(YEAR FROM sale_date) as year"))
                        .distinct
                        .pluck(Arel.sql("EXTRACT(YEAR FROM sale_date)"))
                        .map(&:to_i)
                        .sort
                        .reverse

    # 選択された年度を取得（指定がなければ現在の年）
    @selected_year = params[:year].present? ? params[:year].to_i : Time.current.year

    # 年度に存在するデータがない場合は直近の年度を選択
    @selected_year = @available_years.first if @available_years.present? && !@available_years.include?(@selected_year)

    # 月次レポート計算サービスを初期化
    start_date = Date.new(@selected_year, 1, 1)
    end_date = Date.new(@selected_year, 12, 31)
    calculator = MonthlyReport::Service.new(current_user, start_date, end_date)

    # 月次データを取得
    @monthly_data = calculator.calculate_by_month

    @chart_data = calculator.chart_data
    @table_data = calculator.table_data

    # 合計データを取得
    @totals = calculator.calculate_total
  end
end
