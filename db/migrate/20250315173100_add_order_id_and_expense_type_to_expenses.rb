class AddOrderIdAndExpenseTypeToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_reference :expenses, :order, null: true, foreign_key: true
    add_column :expenses, :expense_type, :string
  end
end
