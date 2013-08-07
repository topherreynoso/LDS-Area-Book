AreaBook::Application.routes.draw do
  resources :users, :activities, :wards
  resources :sessions, only: [:new, :create, :destroy]
  resources :families do
    collection { post :import }
    collection { post :confirm }
  end

  root to: 'static_pages#index'

  match '/help',      	     to: 'static_pages#help',  	   via: 'get'
  match '/tutorial',         to: 'static_pages#tutorial',  via: 'get'
  match '/contact',          to: 'static_pages#contact',   via: 'get' 
  match '/newuser',   	     to: 'users#new', 		   		   via: 'get'
  match '/confirm_user',     to: 'users#confirm',          via: 'post'
  match '/newward',          to: 'wards#new',              via: 'get'
  match '/changeward',       to: 'wards#switch',           via: 'get'
  match '/leaders',          to: 'wards#leaders',          via: 'get'
  match '/confirm_ward',     to: 'wards#confirm',          via: 'post'
  match '/password',         to: 'wards#password',         via: 'get'
  match '/change_password',  to: 'wards#change_password',  via: 'post'
  match '/confirm_password', to: 'wards#confirm_password', via: 'post'
  match '/signin',    	     to: 'sessions#new', 	   		   via: 'get'
  match '/signout',		       to: 'sessions#destroy',  		 via: 'delete'
  match '/wardlist',         to: 'families#ward',     	   via: 'get'
  match '/import',           to: 'families#import',        via: 'get'
  match '/investigators',    to: 'families#investigators', via: 'get'
  match '/watch',            to: 'families#watch',         via: 'get'
  match '/newfamily',	       to: 'families#new',      		 via: 'get'
  match '/newactivity',	     to: 'activities#new',			   via: 'get'
  match '/reports',          to: 'activities#reports',     via: 'get'
  match '/archive',          to: 'activities#archive',     via: 'get'
end
