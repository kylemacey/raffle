Rails.application.routes.draw do
  get 'pos', to: 'pos#new'
  post 'pos/create'
  get 'pos/main'
  get 'pos/custom_price'
  post 'pos/checkout'
  get 'pos/wait_for_pin_pad/:payment_intent_id', to: 'pos#wait_for_pin_pad'
  post 'pos/create_order'
  get 'pos/success/:entry_id', to: 'pos#success', as: :pos_success
  get 'readers', to: 'readers#list'
  post 'readers/assign'
  delete 'readers/cancel_action'
  get 'sign_in', to: 'authentication#new'
  post 'authentication/create'
  delete 'authentication', to: 'authentication#destroy'
  resources :users
  root to: "events#index"

  post 'webhooks/stripe'

  resources :events do
    resources :drawings do
      get :winners
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
