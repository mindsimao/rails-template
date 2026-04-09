Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: [ :index, :new, :create, :destroy ]

  root "home#index"
end
