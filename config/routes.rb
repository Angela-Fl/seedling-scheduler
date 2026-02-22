Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "sessions"
  }

  devise_scope :user do
    get "/demo", to: "sessions#demo", as: :demo
    get "/exit_demo", to: "sessions#exit_demo", as: :exit_demo
  end

  resources :garden_entries
  root "tasks#index"

  get "/up", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] }

  resource :settings, only: [ :edit, :update ]

  # Static pages
  get "getting-started", to: "pages#getting_started", as: :getting_started

  # User feedback submission
  resources :feedback_submissions, only: [ :new, :create ]

  # Admin namespace
  namespace :admin do
    resources :feedback_submissions, only: [ :index, :show, :destroy ] do
      member do
        patch :update_status
      end
    end
  end

  resources :plants do
    member do
      post :regenerate_tasks
      patch :mute
      patch :unmute
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
