class CreateExchangeRates < ActiveRecord::Migration[7.2]
  def change
    create_table :exchange_rates do |t|
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :usd_to_jpy_rate, precision: 10, scale: 2, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :exchange_rates, [ :user_id, :year, :month ], unique: true
  end
end
