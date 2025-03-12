class AddCurrencyIdToPriceAdjustments < ActiveRecord::Migration[7.2]
  def change
    add_reference :price_adjustments, :currency, null: true, foreign_key: true
  end
end
