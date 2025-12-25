# frozen_string_literal: true

# TEMPORARY FIX for Devise 4.9.x deprecation warnings in Rails 8.1+
#
# Rails 8.1+ warns when routing helpers such as `resource` receive a single hash
# argument instead of keyword arguments. Devise 4.9 still passes a hash in the
# implementation of devise_registration, which triggers noisy warnings.
#
# This override swaps that hash for keyword arguments so we stay compatible with
# Rails 8.2 until Devise ships an upstream fix.
#
# Related:
# - https://github.com/heartcombo/devise/issues/5664
# - Rails 8.2 will require keyword arguments for routing helpers
#
# TODO: Remove this file when Devise is updated to a version that fixes this issue
#       (likely Devise 5.0 or a future 4.9.x patch)

ActionDispatch::Routing::Mapper.class_eval do
  protected

  def devise_registration(mapping, controllers)
    path_names = {
      new: mapping.path_names[:sign_up],
      edit: mapping.path_names[:edit],
      cancel: mapping.path_names[:cancel]
    }

    resource :registration,
      only: [ :new, :create, :edit, :update, :destroy ],
      path: mapping.path_names[:registration],
      path_names: path_names,
      controller: controllers[:registrations] do
        get :cancel
      end
  end
end
