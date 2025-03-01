# 本番環境ですべてのテーブルデータを削除する用
namespace :db do
  desc "Clear all data from the database without dropping tables"
  task clear_all: :environment do
    puts "Clearing all data from the database..."

    # 外部キー制約をチェックせずに実行するオプション
    disable_referential_integrity = ActiveRecord::Base.connection.class.include?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)

    if disable_referential_integrity
      ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL DEFERRED") rescue puts "Failed to defer constraints"
    end

    # テーブルを依存関係の順に配列で定義
    tables = [
      "payment_fees",
      "sales",
      "procurements",
      "order_lines",
      "shipments",
      "orders",
      "sku_mappings",
      "manufacturer_skus",
      "seller_skus",
      "manufacturers",
      "expenses",
      "currencies",
      "users"
    ]

    # 各テーブルのデータを削除
    tables.each do |table|
      begin
        puts "Deleting from #{table}..."
        count = ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
        puts "Successfully deleted from #{table}."
      rescue => e
        puts "Error deleting from #{table}: #{e.message}"
      end
    end

    if disable_referential_integrity
      ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL IMMEDIATE") rescue puts "Failed to restore constraints"
    end

    puts "All data has been cleared."
  end
end
