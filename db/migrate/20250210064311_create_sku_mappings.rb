class CreateSkuMappings < ActiveRecord::Migration[7.2]
  def change
    create_table :sku_mappings do |t|
      t.references :seller_sku, null: false, foreign_key: true
      t.references :manufacturer_sku, null: false, foreign_key: true
      t.timestamps
      t.index [ :seller_sku_id, :manufacturer_sku_id ], unique: true, name: 'index_sku_mappings_on_seller_sku_and_manufacturer_sku'
    end
  end
end
