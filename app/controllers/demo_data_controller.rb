class DemoDataController < ApplicationController
  def create
    # デモデータを作成
    source_user_id = 1 # コピー元のユーザーID

    demo_creator = DemoDataCreator.new(current_user)
    result = demo_creator.create_demo_data

    if result
      redirect_to root_path, notice: "デモデータが正常に作成されました。"
    else
      redirect_to root_path, alert: "デモデータの作成に失敗しました。"
    end
  end
end
