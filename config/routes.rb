AreaBook::Application.routes.draw do
  resources :users
  resources :families do
    collection { post :import }
    collection { post :confirm }
  end
  resources :activities
  resources :sessions, only: [:new, :create, :destroy]

  root to: 'static_pages#index'

  match '/help',      	  to: 'static_pages#help', 		  via: 'get'
  match '/newuser',   	  to: 'users#new', 		   		    via: 'get'
  match '/signin',    	  to: 'sessions#new', 	   		  via: 'get'
  match '/signout',		    to: 'sessions#destroy',  		  via: 'delete'
  match '/ward',		      to: 'families#ward',     		  via: 'get'
  match '/import',        to: 'families#import',        via: 'get'
  match '/investigators', to: 'families#investigators', via: 'get'
  match '/watch',         to: 'families#watch',         via: 'get'
  match '/newfamily',	    to: 'families#new',      		  via: 'get'
  match '/newactivity',	  to: 'activities#new',			    via: 'get'
  match '/reports',       to: 'activities#reports',     via: 'get'
  match '/archive',       to: 'activities#archive',     via: 'get'
end
