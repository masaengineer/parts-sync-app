class RemoveCurrencyIdFromRelatedTables < ActiveRecord::Migration[7.2]
  def change
    # order_linesからcurrency_idを削除
    remove_foreign_key :order_lines, :currencies
    remove_column :order_lines, :currency_id
    
    # payment_feesからcurrency_idを削除
    remove_foreign_key :payment_fees, :currencies
    remove_column :payment_fees, :currency_id
    
    # salesからcurrency_idを削除
    remove_foreign_key :sales, :currencies
    remove_column :sales, :currency_id
  end
end
