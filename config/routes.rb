Rails.application.routes.draw do
  resources :pos_products do
    collection do
      get :configuration_fields
    end
  end
  resources :roc_star_prices
  get 'pos', to: 'pos#new'
  post 'pos/create'
  get 'pos/main'
  get 'pos/custom_price'
  post 'pos/checkout'
  get 'pos/wait_for_pin_pad/:payment_intent_id', to: 'pos#wait_for_pin_pad', as: :pos_wait_for_pin_pad
  post 'pos/simulate_payment/:payment_intent_id', to: 'pos#simulate_payment', as: :simulate_payment
  post 'pos/simulate_decline/:payment_intent_id', to: 'pos#simulate_decline', as: :simulate_decline
  post 'pos/create_order'
  get 'pos/success/:order_id', to: 'pos#success', as: :pos_success
  get 'pos/failure/:order_id', to: 'pos#failure', as: :pos_failure
  get 'readers', to: 'readers#list', as: :readers_list
  post 'readers/assign', as: :readers_assign
  post 'readers/create_simulated', as: :readers_create_simulated
  delete 'readers/cancel_action'
  get 'sign_in', to: 'authentication#new'
  post 'authentication/create'
  delete 'authentication', to: 'authentication#destroy'
  resources :users

  # RocStarsController custom actions
  resources :roc_stars, only: [] do
    collection do
      get :prices
      post :create_checkout_session
      get :new_session
      get :success
      get :cancel
    end
  end

  root to: "events#index"

  post 'webhooks/stripe'

  resources :events do
    resources :drawings do
      resources :winners do
        collection do
          get 'by_prize_number'
        end
      end
    end
    resources :entries do
      post :import, on: :collection
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  mount ActionCable.server => '/cable'
end
