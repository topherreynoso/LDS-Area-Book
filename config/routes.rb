AreaBook::Application.routes.draw do
  resources :users, :activities, :wards
  resources :sessions, only: [:new, :create, :destroy]
  resources :families do
    collection { post :import }
    collection { post :confirm }
  end

  root to: 'static_pages#index'

  match '/help',      	      to: 'static_pages#help',  	  via: 'get'
  match '/tutorial',          to: 'static_pages#tutorial',  via: 'get'
  match '/contact',           to: 'static_pages#contact',   via: 'get'
  match '/terms',             to: 'static_pages#terms',     via: 'get'
  match '/privacy',           to: 'static_pages#privacy',   via: 'get'
  match '/new_user',   	      to: 'users#new', 		   		    via: 'get'
  match '/all_users',         to: 'users#all',              via: 'get'
  match '/verify_user',       to: 'users#verify',           via: 'get'
  match '/reset',             to: 'users#reset',            via: 'get'
  match '/send_reset',        to: 'users#send_reset',       via: 'post'
  match '/new_ward',          to: 'wards#new',              via: 'get'
  match '/password',          to: 'wards#password',         via: 'get'
  match '/change_password',   to: 'wards#change_password',  via: 'post'
  match '/confirm_password',  to: 'wards#confirm_password', via: 'post'
  match '/contact_admin',     to: 'wards#contact_admin',    via: 'get'
  match '/email_admin',       to: 'wards#email_admin',      via: 'post'
  match '/signin',    	      to: 'sessions#new', 	   		  via: 'get'
  match '/signout',		        to: 'sessions#destroy',  		  via: 'delete'
  match '/ward_list',         to: 'families#ward',     	    via: 'get'
  match '/import',            to: 'families#import',        via: 'get'
  match '/investigators',     to: 'families#investigators', via: 'get'
  match '/watch',             to: 'families#watch',         via: 'get'
  match '/new_family',	      to: 'families#new',      		  via: 'get'
  match '/new_activity',	    to: 'activities#new',			    via: 'get'
  match '/reports',           to: 'activities#reports',     via: 'get'
  match '/archive',           to: 'activities#archive',     via: 'get'
end
