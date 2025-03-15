class MoveOptionFeeFromProcurementToExpense < ActiveRecord::Migration[7.2]
  def change
    # expenseテーブルにoption_feeカラムを追加
    add_column :expenses, :option_fee, :decimal, precision: 10, scale: 2

    # procurementテーブルからoption_feeカラムを削除
    remove_column :procurements, :option_fee
  end
end
