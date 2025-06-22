Rails.application.routes.draw do
  resources :pos_products
  resources :roc_star_prices
  get 'pos', to: 'pos#new'
  post 'pos/create'
  get 'pos/main'
  get 'pos/custom_price'
  post 'pos/checkout'
  get 'pos/wait_for_pin_pad/:payment_intent_id', to: 'pos#wait_for_pin_pad'
  post 'pos/create_order'
  get 'pos/success/:entry_id', to: 'pos#success', as: :pos_success
  get 'readers', to: 'readers#list', as: :readers_list
  post 'readers/assign', as: :readers_assign
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
