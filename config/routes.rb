# == Route Map
#

Rails.application.routes.draw do
  root to: "sales_reports#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :users, only: [ :index, :show ]
  resources :pl_reports, only: [ :index ]
  resources :sales_reports, only: [ :index, :show ]
  resources :data_imports, only: [ :index, :show ] do
    collection do
      post :import
    end
  end
  resources :ebay_orders, only: [ :index ] do
    collection do
      post :import_orders
    end
  end

  # 静的ページのルーティング
  get "privacy_policy", to: "static_pages#privacy_policy"
  get "terms_of_service", to: "static_pages#terms_of_service"

  # ヘルスチェック用エンドポイント
  get 'health', to: 'application#health'
end
