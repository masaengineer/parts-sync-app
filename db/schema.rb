# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_03_23_152706) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "currencies", force: :cascade do |t|
    t.string "code", null: false
    t.string "name"
    t.string "symbol"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "year"
    t.integer "month"
    t.string "item_name"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "option_fee", precision: 10, scale: 2
    t.bigint "order_id"
    t.string "expense_type"
    t.index ["order_id"], name: "index_expenses_on_order_id"
  end

  create_table "manufacturer_skus", force: :cascade do |t|
    t.string "sku_code"
    t.bigint "manufacturer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manufacturer_id"], name: "index_manufacturer_skus_on_manufacturer_id"
    t.index ["sku_code"], name: "index_manufacturer_skus_on_sku_code", unique: true
  end

  create_table "manufacturers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_manufacturers_on_name"
  end

  create_table "order_lines", force: :cascade do |t|
    t.bigint "seller_sku_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.bigint "line_item_id"
    t.string "line_item_name"
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["seller_sku_id"], name: "index_order_lines_on_seller_sku_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number"
    t.date "sale_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "currency_id"
    t.index ["currency_id"], name: "index_orders_on_currency_id"
    t.index ["order_number"], name: "index_orders_on_order_number"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_fees", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fee_category"
    t.decimal "fee_amount"
    t.string "transaction_type"
    t.string "transaction_id"
    t.index ["order_id"], name: "index_payment_fees_on_order_id"
    t.index ["transaction_id", "transaction_type", "fee_category"], name: "index_payment_fees_on_transaction_id_type_and_category", unique: true
  end

  create_table "price_adjustments", force: :cascade do |t|
    t.bigint "seller_sku_id", null: false
    t.datetime "adjustment_date"
    t.decimal "adjustment_amount", precision: 10, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "currency_id"
    t.index ["currency_id"], name: "index_price_adjustments_on_currency_id"
    t.index ["seller_sku_id"], name: "index_price_adjustments_on_seller_sku_id"
  end

  create_table "procurements", force: :cascade do |t|
    t.decimal "purchase_price"
    t.decimal "forwarding_fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id", null: false
    t.decimal "handling_fee", precision: 10, scale: 2
    t.index ["order_id"], name: "index_procurements_on_order_id", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.decimal "order_net_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "order_gross_amount"
    t.decimal "to_usd_rate", precision: 10, scale: 6, default: "1.0"
    t.string "transaction_id"
    t.index ["order_id"], name: "index_sales_on_order_id"
  end

  create_table "seller_skus", force: :cascade do |t|
    t.string "sku_code", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_id"
    t.index ["item_id"], name: "index_seller_skus_on_item_id"
    t.index ["sku_code"], name: "index_seller_skus_on_sku_code", unique: true
  end

  create_table "shipments", force: :cascade do |t|
    t.decimal "customer_international_shipping"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.string "tracking_number"
    t.bigint "currency_id"
    t.index ["currency_id"], name: "index_shipments_on_currency_id"
    t.index ["order_id"], name: "index_shipments_on_order_id"
  end

  create_table "sku_mappings", force: :cascade do |t|
    t.bigint "seller_sku_id", null: false
    t.bigint "manufacturer_sku_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manufacturer_sku_id"], name: "index_sku_mappings_on_manufacturer_sku_id"
    t.index ["seller_sku_id", "manufacturer_sku_id"], name: "index_sku_mappings_on_seller_sku_and_manufacturer_sku", unique: true
    t.index ["seller_sku_id"], name: "index_sku_mappings_on_seller_sku_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "profile_picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "last_name"
    t.string "first_name"
    t.string "provider"
    t.string "uid"
    t.datetime "ebay_orders_last_synced_at"
    t.datetime "ebay_transaction_fees_last_synced_at"
    t.boolean "is_demo", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_demo"], name: "index_users_on_is_demo"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "expenses", "orders"
  add_foreign_key "manufacturer_skus", "manufacturers"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "seller_skus"
  add_foreign_key "orders", "currencies"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_fees", "orders"
  add_foreign_key "price_adjustments", "currencies"
  add_foreign_key "price_adjustments", "seller_skus"
  add_foreign_key "procurements", "orders"
  add_foreign_key "sales", "orders"
  add_foreign_key "shipments", "currencies"
  add_foreign_key "sku_mappings", "manufacturer_skus"
  add_foreign_key "sku_mappings", "seller_skus"
end
