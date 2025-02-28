class AddCurrencyReferencesToTables < ActiveRecord::Migration[7.2]
  def change
    # orders テーブルの修正
    add_reference :orders, :currency, foreign_key: true
    
    # sales テーブルの修正
    add_reference :sales, :currency, foreign_key: true
    
    # order_lines テーブルの修正
    add_reference :order_lines, :currency, foreign_key: true
    
    # payment_fees テーブルの修正
    add_reference :payment_fees, :currency, foreign_key: true
    
    # shipments テーブルの修正
    add_reference :shipments, :currency, foreign_key: true
  end
end
