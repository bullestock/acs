Rails.application.routes.draw do
  get 'logs/new'

  get 'permissions/new'

  get 'static_pages/home'

  get 'static_pages/help'

  root   'static_pages#home'
  get    '/help',    to: 'static_pages#help'
  get    '/about',   to: 'static_pages#about'
  get    '/contact', to: 'static_pages#contact'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'

  resources :users
  resources :machines
  resources :logs
end
