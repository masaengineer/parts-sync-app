module Demo
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_demo_user
    before_action :set_demo_mode_notice

    private

    def set_demo_user
      @demo_user = fetch_demo_user
      redirect_to root_path, alert: "デモモードは現在利用できません" unless @demo_user
    end

    def fetch_demo_user
      User.where(is_demo: true).order(id: :asc).first
    end

    def current_user
      @demo_user
    end
  end
end
