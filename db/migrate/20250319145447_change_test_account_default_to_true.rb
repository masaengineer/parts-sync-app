class ChangeTestAccountDefaultToTrue < ActiveRecord::Migration[7.2]
  def up
    # 既存のレコードをすべてtrueに更新
    User.update_all(test_account: true)

    # デフォルト値をtrueに変更
    change_column_default :users, :test_account, from: false, to: true
  end

  def down
    # 元のデフォルト値falseに戻す
    change_column_default :users, :test_account, from: true, to: false

    # 既存のレコードはリセットしない（手動で設定されている可能性があるため）
  end
end
