Rails.application.routes.draw do
  devise_for :users
  # Defines the root path route ("/")
  # root "posts#index"
  root to: "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  # Custom routes
  resources :stories, only: [:new, :show, :create, :index] do
    resources :messages, only: [:create]
  end
end
