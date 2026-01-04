Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :garden_entries
  root "tasks#index"

  get "/up", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] }

  resource :settings, only: [ :edit, :update ]

  resources :plants do
    member do
      post :regenerate_tasks
    end
  end

  resources :tasks, only: [ :index, :create, :update, :destroy ] do
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
