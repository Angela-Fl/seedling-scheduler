class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :block_demo_mutations

  private

  def block_demo_mutations
    return unless current_user&.demo?
    return unless request.post? || request.patch? || request.put? || request.delete?

    # Allow demo login and logout actions to proceed
    return if controller_name == "sessions" && (action_name == "demo" || action_name == "destroy")

    error_message = "Demo mode: changes are disabled. Sign up to create your own garden!"

    respond_to do |format|
      format.html do
        flash[:alert] = error_message

        # Check if this is a Turbo request
        if turbo_frame_request? || request.xhr?
          # For Turbo/AJAX requests, return 422 to keep them on the page
          head :unprocessable_entity
        else
          # For regular requests, redirect
          redirect_to request.referer || root_path, allow_other_host: false
        end
      end

      format.json do
        render json: { error: error_message }, status: :forbidden
      end
    end
  end
end
