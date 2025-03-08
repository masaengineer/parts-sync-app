class RenameExchangerateToToUsdRate < ActiveRecord::Migration[7.2]
  def change
    rename_column :sales, :exchangerate, :to_usd_rate
  end
end
