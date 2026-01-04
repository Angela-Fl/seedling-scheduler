# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Override the after_inactive_sign_up_path_for method to redirect to sign in
  # with a custom message after successful signup (when email confirmation is pending)
  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  # Override create to set custom flash message for unconfirmed users
  def create
    super do |resource|
      if resource.persisted? && !resource.active_for_authentication?
        set_flash_message! :notice, :signed_up_but_unconfirmed
        # The custom message will be set in the locale file
      end
    end
  end
end
