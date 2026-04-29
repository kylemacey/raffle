Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # Mount Action Cable for real-time features like Turbo Streams.
  mount ActionCable.server => '/cable'

  # Set the root path of the application.
  root to: "events#index"

  # == AUTHENTICATION ==
  # Routes for signing in and out.
  get 'sign_in', to: 'authentication#new'
  post 'authentication/create'
  delete 'authentication', to: 'authentication#destroy'

  # == POINT OF SALE (POS) & ORDERS ==
  # Core interface for sales, checkout, and order viewing.
  get 'pos', to: 'pos#new'
  post 'pos/create'
  get 'pos/main'
  get 'pos/custom_price'
  post 'pos/checkout'
  get 'pos/search_customers'
  get 'pos/wait_for_pin_pad/:payment_intent_id', to: 'pos#wait_for_pin_pad', as: :pos_wait_for_pin_pad
  get 'pos/success/:order_id', to: 'pos#success', as: :pos_success
  get 'pos/failure/:order_id', to: 'pos#failure', as: :pos_failure
  post 'pos/create_order'

  resources :orders, only: [:index, :show, :destroy]

  # == CARD READERS & TERMINAL ==
  # Routes for managing and interacting with Stripe Terminal readers.
  get 'readers', to: 'readers#list', as: :readers_list
  post 'readers/assign', as: :readers_assign
  post 'readers/create_simulated', as: :readers_create_simulated
  delete 'readers/cancel_action'

  # == SIMULATED PAYMENTS (Development Only) ==
  post 'pos/simulate_payment/:payment_intent_id', to: 'pos#simulate_payment', as: :simulate_payment
  post 'pos/simulate_decline/:payment_intent_id', to: 'pos#simulate_decline', as: :simulate_decline

  # == WEBHOOKS ==
  # Incoming webhooks from external services like Stripe.
  post 'webhooks/stripe'

  # == RESTful RESOURCES ==
  # These routes follow standard RESTful patterns.

  # Events are the top-level resource for drawings and entries.
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

  # == ADMIN RESOURCES ==
  # User management.
  resources :users

  # Product and Price Management.
  resources :pos_products do
    patch :reorder, on: :collection
    get :configuration_fields, on: :collection
  end
  resources :roc_star_prices

  # == ROC STARS SUBSCRIPTIONS ==
  # Custom flow for "Roc Stars" recurring subscriptions.
  resources :roc_stars, only: [] do
    collection do
      get :prices
      post :create_checkout_session
      get :new_session
      get :success
      get :cancel
    end
  end
end
