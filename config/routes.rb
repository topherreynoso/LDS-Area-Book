AreaBook::Application.routes.draw do
  resources :users
  resources :sessions, only: [:new, :create, :destroy]

  root to: 'static_pages#home'

  match '/help',    to: 'static_pages#help', via: 'get'
  match '/newuser', to: 'users#new', 		 via: 'get'
  match '/signin',  to: 'sessions#new', 	 via: 'get'
  match '/signout', to: 'sessions#destroy',	 via: 'delete'
end
