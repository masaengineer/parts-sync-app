class RemovePostalTrackingDataFromShipments < ActiveRecord::Migration[7.2]
  def change
    remove_column :shipments, :postal_decision_amount, :decimal
    remove_column :shipments, :postal_tracking_updated_at, :datetime
  end
end
