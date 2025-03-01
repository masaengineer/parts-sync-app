class AddTransactionIdToSales < ActiveRecord::Migration[7.2]
  def change
    add_column :sales, :transaction_id, :string
  end
end
