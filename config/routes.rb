Rails.application.routes.draw do
  devise_for :users
  get "landing/index"
  resources :tasks

  # アプリケーションのルートパスを定義
  root "landing#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
