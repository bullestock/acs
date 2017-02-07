Rails.application.routes.draw do
  resources :users
  resources :machines
  
  root 'welcome#index'
end
