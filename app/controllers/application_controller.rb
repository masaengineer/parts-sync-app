class ApplicationController < ActionController::Base
  layout :layout_by_resource
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  JPY_RATE = 150

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :last_name, :first_name, :email, :password, :password_confirmation, :agreement ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :last_name, :first_name, :email, :password, :password_confirmation, :agreement ])
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def health
    ActiveRecord::Base.connection.execute("SELECT 1")
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")).ping
    render json: { status: "OK", time: Time.current }, status: :ok
  rescue => e
    render json: { status: "ERROR", error: e.message }, status: :internal_server_error
  end
end
