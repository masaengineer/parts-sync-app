class ChangeCurrencyReferencesToCurrencyCode < ActiveRecord::Migration[7.2]
  def change
    # 外部キー制約を削除
    remove_foreign_key :orders, :currencies if foreign_key_exists?(:orders, :currencies)
    remove_foreign_key :sales, :currencies if foreign_key_exists?(:sales, :currencies)
    remove_foreign_key :order_lines, :currencies if foreign_key_exists?(:order_lines, :currencies)
    remove_foreign_key :payment_fees, :currencies if foreign_key_exists?(:payment_fees, :currencies)
    remove_foreign_key :shipments, :currencies if foreign_key_exists?(:shipments, :currencies)
    
    # 参照カラムを削除
    remove_reference :orders, :currency, index: true
    remove_reference :sales, :currency, index: true
    remove_reference :order_lines, :currency, index: true
    remove_reference :payment_fees, :currency, index: true
    remove_reference :shipments, :currency, index: true
    
    # 通貨コードカラムを追加
    add_column :orders, :currency_code, :string
    add_column :sales, :currency_code, :string
    add_column :order_lines, :currency_code, :string
    add_column :payment_fees, :currency_code, :string
    add_column :shipments, :currency_code, :string
    
    # インデックスを追加
    add_index :orders, :currency_code
    add_index :sales, :currency_code
    add_index :order_lines, :currency_code
    add_index :payment_fees, :currency_code
    add_index :shipments, :currency_code
    
    # 不要になったcurrenciesテーブルを削除
    drop_table :currencies
  end
  
  private
  
  def foreign_key_exists?(from_table, to_table)
    foreign_keys = ActiveRecord::Base.connection.foreign_keys(from_table)
    foreign_keys.any? { |fk| fk.to_table.to_s == to_table.to_s }
  end
end
