class AddPostalTrackingDataToShipments < ActiveRecord::Migration[7.2]
  def change
    add_column :shipments, :postal_decision_amount, :decimal, precision: 10, scale: 2
    add_column :shipments, :postal_tracking_updated_at, :datetime
  end
end
