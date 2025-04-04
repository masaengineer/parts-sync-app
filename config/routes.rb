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

  # 静的ページのルーティング
  get "privacy_policy", to: "static_pages#privacy_policy"
  get "terms_of_service", to: "static_pages#terms_of_service"

  # ヘルスチェック用エンドポイント
  get "health", to: "application#health"
end
