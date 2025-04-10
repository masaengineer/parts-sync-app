class MonthlyReportsController < ApplicationController
  def index
    @available_years = current_user.orders
                        .select(Arel.sql("EXTRACT(YEAR FROM sale_date) as year"))
                        .distinct
                        .pluck(Arel.sql("EXTRACT(YEAR FROM sale_date)"))
                        .map(&:to_i)
                        .sort
                        .reverse

    @selected_year = params[:year].present? ? params[:year].to_i : Time.current.year

    @selected_year = @available_years.first if @available_years.present? && !@available_years.include?(@selected_year)

    start_date = Date.new(@selected_year, 1, 1)
    end_date = Date.new(@selected_year, 12, 31)
    calculator = MonthlyReport::Service.new(current_user, start_date, end_date)

    @monthly_data = calculator.calculate_by_month

    @chart_data = calculator.chart_data
    @table_data = calculator.table_data

    @totals = calculator.calculate_total
  end
end
