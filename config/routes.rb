Rails.application.routes.draw do
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
