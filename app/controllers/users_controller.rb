class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :toggle_demo_mode ]

  def index
    redirect_to user_path(current_user)
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to edit_user_path(@user), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_demo_mode
    current_value = @user.is_demo
    if @user.update(is_demo: !current_value)
      new_mode = @user.is_demo ? "デモモード" : "本番モード"
      redirect_to user_path(@user), notice: "#{new_mode}に切り替えました"
    else
      redirect_to user_path(@user), alert: "モードの切り替えに失敗しました"
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :profile_picture_url)
  end
end
