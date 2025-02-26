class RemoveSkusAndOrderSkuLinks < ActiveRecord::Migration[7.2]
  def up
    drop_table :order_sku_links
    drop_table :skus
  end

  def down
    # skusテーブルの再作成
    create_table :skus do |t|
      t.string :sku_code
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "quantity"
      t.string "international_title"
      t.bigint "manufacturer_id"
      t.index [ "manufacturer_id" ], name: "index_skus_on_manufacturer_id"
      t.index [ "sku_code" ], name: "index_skus_on_sku_code"
    end

    # order_sku_linksテーブルの再作成
    create_table :order_sku_links do |t|
      t.bigint "order_id", null: false
      t.bigint "sku_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "order_id", "sku_id" ], name: "index_order_sku_links_on_order_id_and_sku_id", unique: true
      t.index [ "order_id" ], name: "index_order_sku_links_on_order_id"
      t.index [ "sku_id" ], name: "index_order_sku_links_on_sku_id"
    end

    add_foreign_key "order_sku_links", "orders"
    add_foreign_key "order_sku_links", "skus"
    add_foreign_key "skus", "manufacturers"
  end
end
