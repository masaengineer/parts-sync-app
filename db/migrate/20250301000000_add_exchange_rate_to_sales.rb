class AddExchangeRateToSales < ActiveRecord::Migration[7.0]
  def change
    add_column :sales, :exchangerate, :decimal, precision: 10, scale: 6, default: 1.0
  end
end
