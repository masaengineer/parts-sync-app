class AddTrackingNumberToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :tracking_number, :string
  end
end
