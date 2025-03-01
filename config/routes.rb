Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "user_meals#index"

  resources :meals, only: [ :index, :show ] do
    collection do
      get :search
    end
  end

  resources :user_meals do
    member do
      post :retry_processing
    end
  end
  get "nutrition_summary", to: "nutrition_summary#show", as: :nutrition_summary

  get "/global_settings", to: "global_settings#index", as: :global_settings
  patch "/global_settings", to: "global_settings#update", as: :update_global_settings

  resource :profile, controller: "user_profiles"
  resource :onboarding, controller: "onboarding"

  # Family management
  get "/family", to: "invites#index", as: :family
  post "/family/invites/regenerate", to: "invites#regenerate", as: :regenerate_invite
  post "/family/invites/invalidate", to: "invites#invalidate", as: :invalidate_invite
  delete "/family/users/:id", to: "invites#destroy_user", as: :delete_family_user

  # Join routes
  get "/join/:token", to: "joins#new", as: :join
  post "/join/:token", to: "joins#create", as: :create_user
end
