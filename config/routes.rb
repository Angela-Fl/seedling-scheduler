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

  # Reports the commit this image was built from, so a deploy can be identified
  # without matching timestamps by hand. GIT_SHA is baked in by the Dockerfile;
  # it reads "unknown" for local runs and any build that omitted the build arg.
  # Defined as a proc, like /up, to stay outside ApplicationController's
  # authenticate_user! filter.
  #
  # presence, not ENV.fetch: passing --build-arg GIT_SHA= with an empty value
  # overrides the Dockerfile's ARG default, so the variable is present but blank.
  # fetch's default only covers a missing key and would report "" -- which reads
  # like a malfunction rather than "nobody supplied a SHA".
  get "/version", to: proc {
    body = { git_sha: ENV["GIT_SHA"].presence || "unknown" }.to_json
    [ 200, { "Content-Type" => "application/json" }, [ body ] ]
  }

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
