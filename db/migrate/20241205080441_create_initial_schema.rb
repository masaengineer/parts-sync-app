  class CreateInitialSchema < ActiveRecord::Migration[7.2]
    def change
      enable_extension "plpgsql"

      create_table "expenses", force: :cascade do |t|
        t.integer "year"
        t.integer "month"
        t.string "item_name"
        t.decimal "amount"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
      end

      create_table "manufacturers", force: :cascade do |t|
        t.string "name"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index [ "name" ], name: "index_manufacturers_on_name"
      end

      create_table "order_sku_links", force: :cascade do |t|
        t.bigint "order_id", null: false
        t.bigint "sku_id", null: false
        t.integer "quantity", null: false
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.decimal "sku_net_amount", precision: 10, scale: 2
        t.decimal "sku_gross_amount", precision: 10, scale: 2
        t.index [ "order_id", "sku_id" ], name: "index_order_sku_links_on_order_id_and_sku_id", unique: true
        t.index [ "order_id" ], name: "index_order_sku_links_on_order_id"
        t.index [ "sku_gross_amount" ], name: "index_order_sku_links_on_sku_gross_amount"
        t.index [ "sku_id" ], name: "index_order_sku_links_on_sku_id"
        t.index [ "sku_net_amount" ], name: "index_order_sku_links_on_sku_net_amount"
      end

      create_table "orders", force: :cascade do |t|
        t.string "order_number"
        t.date "sale_date"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index [ "order_number" ], name: "index_orders_on_order_number"
      end

      create_table "payment_fees", force: :cascade do |t|
        t.bigint "order_id", null: false
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.string "fee_category"
        t.decimal "fee_amount"
        t.index [ "order_id" ], name: "index_payment_fees_on_order_id"
      end

      create_table "procurements", force: :cascade do |t|
        t.decimal "purchase_price"
        t.decimal "forwarding_fee"
        t.decimal "photo_fee"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.bigint "sku_id"
        t.index [ "sku_id" ], name: "index_procurements_on_sku_id"
      end

      create_table "products", force: :cascade do |t|
        t.string "oem_part_number"
        t.string "international_title"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.bigint "manufacturer_id", null: false
        t.index [ "manufacturer_id" ], name: "index_products_on_manufacturer_id"
        t.index [ "oem_part_number" ], name: "index_products_on_oem_part_number"
      end

      create_table "sales", force: :cascade do |t|
        t.bigint "order_id", null: false
        t.decimal "order_net_amount"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.decimal "order_gross_amount"
        t.index [ "order_id" ], name: "index_sales_on_order_id"
      end

      create_table "shipments", force: :cascade do |t|
        t.bigint "order_id", null: false
        t.string "tracking_number"
        t.decimal "customer_international_shipping"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.integer "cpass_trade_id"
        t.index [ "order_id" ], name: "index_shipments_on_order_id"
      end

      create_table "sku_product_links", force: :cascade do |t|
        t.bigint "sku_id", null: false
        t.bigint "product_id", null: false
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index [ "product_id" ], name: "index_sku_product_links_on_product_id"
        t.index [ "sku_id", "product_id" ], name: "index_sku_product_links_on_sku_id_and_product_id", unique: true
        t.index [ "sku_id" ], name: "index_sku_product_links_on_sku_id"
      end

      create_table "skus", force: :cascade do |t|
        t.string "sku_code"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index [ "sku_code" ], name: "index_skus_on_sku_code"
      end

      create_table "users", force: :cascade do |t|
        t.string "name"
        t.string "email", null: false
        t.string "profile_picture_url"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.string "encrypted_password", default: "", null: false
        t.string "reset_password_token"
        t.datetime "reset_password_sent_at"
        t.datetime "remember_created_at"
        t.index [ "email" ], name: "index_users_on_email", unique: true
        t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
      end

      add_foreign_key "order_sku_links", "orders"
      add_foreign_key "order_sku_links", "skus"
      add_foreign_key "payment_fees", "orders"
      add_foreign_key "procurements", "skus"
      add_foreign_key "products", "manufacturers"
      add_foreign_key "sales", "orders"
      add_foreign_key "shipments", "orders"
      add_foreign_key "sku_product_links", "products"
      add_foreign_key "sku_product_links", "skus"
    end
  end
