class RestoreCurrencyTable < ActiveRecord::Migration[7.2]
  def change
    # Currencyテーブルの再作成
    create_table :currencies do |t|
      t.string :code, null: false
      t.string :name
      t.string :symbol
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :currencies, :code, unique: true
    
    # 通貨コードカラムを削除
    remove_index :orders, :currency_code if index_exists?(:orders, :currency_code)
    remove_index :sales, :currency_code if index_exists?(:sales, :currency_code)
    remove_index :order_lines, :currency_code if index_exists?(:order_lines, :currency_code)
    remove_index :payment_fees, :currency_code if index_exists?(:payment_fees, :currency_code)
    remove_index :shipments, :currency_code if index_exists?(:shipments, :currency_code)
    
    remove_column :orders, :currency_code if column_exists?(:orders, :currency_code)
    remove_column :sales, :currency_code if column_exists?(:sales, :currency_code)
    remove_column :order_lines, :currency_code if column_exists?(:order_lines, :currency_code)
    remove_column :payment_fees, :currency_code if column_exists?(:payment_fees, :currency_code)
    remove_column :shipments, :currency_code if column_exists?(:shipments, :currency_code)
    
    # 外部キー参照の追加
    add_reference :orders, :currency, foreign_key: true
    add_reference :sales, :currency, foreign_key: true
    add_reference :order_lines, :currency, foreign_key: true
    add_reference :payment_fees, :currency, foreign_key: true
    add_reference :shipments, :currency, foreign_key: true
  end
end
