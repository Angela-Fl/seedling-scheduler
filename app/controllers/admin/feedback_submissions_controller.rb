module Admin
  class FeedbackSubmissionsController < ApplicationController
    before_action :require_admin!
    before_action :set_feedback_submission, only: [ :show, :update_status, :destroy ]

    def index
      @feedback_submissions = FeedbackSubmission
        .includes(:user)
        .by_status(params[:status])
        .newest_first
    end

    def show
    end

    def update_status
      if @feedback_submission.update(status: params[:status])
        redirect_to admin_feedback_submission_path(@feedback_submission),
                    notice: "Status updated to #{params[:status]}"
      else
        redirect_to admin_feedback_submission_path(@feedback_submission),
                    alert: "Failed to update status"
      end
    end

    def destroy
      @feedback_submission.destroy!
      redirect_to admin_feedback_submissions_path, notice: "Feedback submission deleted successfully."
    rescue => e
      redirect_to admin_feedback_submissions_path, alert: "Failed to delete feedback submission: #{e.message}"
    end

    private

    def set_feedback_submission
      @feedback_submission = FeedbackSubmission.find(params[:id])
    end

    def require_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "You are not authorized to access this page."
      end
    end
  end
end
