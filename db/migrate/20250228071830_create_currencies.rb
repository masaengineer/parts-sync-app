class CreateCurrencies < ActiveRecord::Migration[7.2]
  def change
    create_table :currencies do |t|
      t.string :code, null: false           # 通貨コード (USD, JPY等)
      t.string :name                        # 通貨名 (US Dollar, Japanese Yen等)
      t.string :symbol                      # 通貨記号 ($, ¥等)
      t.boolean :active, default: true      # 有効/無効フラグ
      t.timestamps

      t.index :code, unique: true
    end
  end
end
