class AddDemoFlagToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_demo, :boolean, default: true, null: false
    add_index :users, :is_demo
  end
end
