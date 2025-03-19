class AddTestAccountToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :test_account, :boolean, default: false, null: false
  end
end
