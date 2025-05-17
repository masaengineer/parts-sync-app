# == Route Map
#

Rails.application.routes.draw do
  root to: "sales_reports#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :users, only: [ :index, :show ] do
    member do
      patch :toggle_demo_mode
    end
  end

  resources :monthly_reports, only: [ :index ]

  namespace :monthly_reports do
    resources :expenses
  end

  resources :sales_reports, only: [ :index, :show ]
  resources :price_adjustments, only: [ :new, :create ]

  resources :data_imports, only: [ :index, :show ] do
    collection do
      post :import
    end
  end

  resources :demo_data, only: [ :create ]

  resources :ebay_orders, only: [ :index ] do
    collection do
      post :import_orders
    end
  end

  # デモモード用のルート
  namespace :demo do
    get '/', to: 'demo#index'
    get 'sales_reports', to: 'demo#sales_reports'
    get 'monthly_reports', to: 'demo#monthly_reports'
    get 'profile', to: 'demo#user_profile'
  end

  # 静的ページのルーティング
  get "privacy_policy", to: "static_pages#privacy_policy"
  get "terms_of_service", to: "static_pages#terms_of_service"
  get "scta", to: "static_pages#scta"
  get "landing", to: "static_pages#landing"

  # Rails標準のヘルスチェックエンドポイント
  get "up" => "rails/health#show", as: :rails_health_check
end
