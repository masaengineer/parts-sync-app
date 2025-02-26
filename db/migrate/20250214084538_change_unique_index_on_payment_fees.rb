class ChangeUniqueIndexOnPaymentFees < ActiveRecord::Migration[7.2]
  def change
    # 既存のtransaction_id単体のユニークインデックスを削除
    remove_index :payment_fees, :transaction_id, unique: true

    # transaction_idとtransaction_typeの組み合わせでユニークインデックスを追加
    add_index :payment_fees, [ :transaction_id, :transaction_type ], unique: true
  end
end
