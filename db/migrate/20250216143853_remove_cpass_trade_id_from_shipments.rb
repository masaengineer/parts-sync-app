class RemoveCpassTradeIdFromShipments < ActiveRecord::Migration[7.2]
  def change
    remove_column :shipments, :cpass_trade_id, :integer
  end
end
