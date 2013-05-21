AreaBook::Application.routes.draw do
  resources :users
  root to: 'static_pages#home'
  match '/help',    to: 'static_pages#help',    via: 'get'
  match '/signin',  to: 'users#new',            via: 'get'
end
