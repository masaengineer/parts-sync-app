class AddFeeCategoryToUniqueIndexOnPaymentFees < ActiveRecord::Migration[7.2]
  def change
    # 既存のtransaction_idとtransaction_typeの組み合わせのユニークインデックスを削除
    remove_index :payment_fees, [ :transaction_id, :transaction_type ], unique: true

    # transaction_id, transaction_type, fee_categoryの組み合わせでユニークインデックスを追加
    add_index :payment_fees, [ :transaction_id, :transaction_type, :fee_category ], unique: true, name: 'index_payment_fees_on_transaction_id_type_and_category'
  end
end
