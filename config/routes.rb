Rails.application.routes.draw do
  get 'pos', to: 'pos#new'
  post 'pos/create'
  get 'pos/main'
  get 'pos/custom_price'
  post 'pos/checkout'
  post 'pos/create_order'
  get 'pos/success/:entry_id', to: 'pos#success', as: :pos_success
  get 'readers', to: 'readers#list'
  post 'readers/assign'
  get 'sign_in', to: 'authentication#new'
  post 'authentication/create'
  delete 'authentication', to: 'authentication#destroy'
  resources :users
  root to: "events#index"

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
end
