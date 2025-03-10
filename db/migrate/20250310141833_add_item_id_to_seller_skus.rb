class AddItemIdToSellerSkus < ActiveRecord::Migration[7.2]
  def change
    add_column :seller_skus, :item_id, :string
    add_index :seller_skus, :item_id
  end
end
