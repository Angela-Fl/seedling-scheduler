class FeedbackSubmissionsController < ApplicationController
  def new
    @feedback_submission = FeedbackSubmission.new
    @from_page = params[:from]
  end

  def create
    @feedback_submission = current_user.feedback_submissions.new(feedback_params)
    @feedback_submission.page = params[:feedback_submission][:page]
    @feedback_submission.user_agent = request.user_agent

    if @feedback_submission.save
      redirect_to root_path, notice: "Thank you for your feedback! We'll review it soon."
    else
      @from_page = params[:feedback_submission][:page]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    # NOTE: We intentionally do NOT permit :user_id, :status, :page, or :user_agent
    params.require(:feedback_submission).permit(:category, :message, :email, :wants_reply)
  end
end
