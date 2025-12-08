Rails.application.routes.draw do
  root "tasks#index"

  resource :settings, only: [ :edit, :update ]

  resources :plants do
    member do
      post :regenerate_tasks
    end
  end

  resources :tasks, only: [ :index ]
end
