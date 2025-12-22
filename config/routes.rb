Rails.application.routes.draw do
  root "tasks#index"

  resource :settings, only: [ :edit, :update ]

  resources :plants do
    member do
      post :regenerate_tasks
    end
  end

  resources :tasks, only: [ :index, :create, :update ] do
    collection do
      get :calendar
    end
    member do
      patch :complete
      patch :skip
      patch :reset
    end
  end
end
