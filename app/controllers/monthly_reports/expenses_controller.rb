module MonthlyReports
  class ExpensesController < ApplicationController
    before_action :set_expense, only: [ :edit, :update, :destroy ]
    before_action :set_year_and_month, only: [ :index, :new, :create ]

    def index
      @expenses = Expense.where(year: @year, month: @month).order(:item_name)
    end

    def new
      @expense = Expense.new(year: @year, month: @month)
    end

    def create
      @expense = Expense.new(expense_params)

      if @expense.save
        redirect_to monthly_reports_expenses_path(year: @expense.year, month: @expense.month), notice: "販管費を登録しました"
      else
        flash.now[:error] = "入力内容に#{@expense.errors.count}件のエラーがあります"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @expense.update(expense_params)
        redirect_to monthly_reports_expenses_path(year: @expense.year, month: @expense.month), notice: "販管費を更新しました"
      else
        flash.now[:error] = "入力内容に#{@expense.errors.count}件のエラーがあります"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      year = @expense.year
      month = @expense.month
      @expense.destroy
      redirect_to monthly_reports_expenses_path(year: year, month: month), notice: "販管費を削除しました"
    end

    private

    def set_expense
      @expense = Expense.find(params[:id])
    end

    def set_year_and_month
      @year = params[:year].present? ? params[:year].to_i : Time.current.year
      @month = params[:month].present? ? params[:month].to_i : Time.current.month
    end

    def expense_params
      params.require(:expense).permit(:year, :month, :item_name, :amount)
    end
  end
end
