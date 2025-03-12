class CreatePriceAdjustments < ActiveRecord::Migration[7.2]
  def change
    create_table :price_adjustments do |t|
      t.references :seller_sku, null: false, foreign_key: true
      t.datetime :adjustment_date
      t.decimal :adjustment_amount, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
