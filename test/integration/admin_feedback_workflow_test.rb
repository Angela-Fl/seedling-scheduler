require "test_helper"

class AdminFeedbackWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @non_admin = users(:two)
    @feedback = feedback_submissions(:one)

    ENV["ADMIN_EMAILS"] = @admin.email
  end

  teardown do
    ENV.delete("ADMIN_EMAILS")
  end

  test "admin can view all feedback submissions" do
    sign_in @admin

    get admin_feedback_submissions_path
    assert_response :success

    # Should see all feedback in the list
    assert_select "tbody tr", count: FeedbackSubmission.count

    # Should see feedback from different users
    assert_match feedback_submissions(:one).message_preview, response.body
    assert_match feedback_submissions(:two).message_preview, response.body
  end

  test "admin can filter feedback by status" do
    sign_in @admin

    # Filter by "new" status
    get admin_feedback_submissions_path(status: "new")
    assert_response :success

    new_feedbacks = FeedbackSubmission.where(status: "new")
    assert_select "tbody tr", count: new_feedbacks.count

    # Filter by "reviewed" status
    get admin_feedback_submissions_path(status: "reviewed")
    assert_response :success

    reviewed_feedbacks = FeedbackSubmission.where(status: "reviewed")
    assert_select "tbody tr", count: reviewed_feedbacks.count
  end

  test "admin can view feedback detail page" do
    sign_in @admin

    get admin_feedback_submission_path(@feedback)
    assert_response :success

    assert_select "h2", text: /Feedback ##{@feedback.id}/
    assert_match @feedback.message, response.body
    assert_match @feedback.user.email, response.body
    assert_match @feedback.category, response.body
  end

  test "admin can update feedback status" do
    sign_in @admin

    # Start with "new" status
    assert_equal "new", @feedback.status

    # Update to "reviewed"
    patch update_status_admin_feedback_submission_path(@feedback), params: { status: "reviewed" }
    assert_redirected_to admin_feedback_submission_path(@feedback)

    @feedback.reload
    assert_equal "reviewed", @feedback.status

    # Follow redirect and see success message
    follow_redirect!
    assert_match /status updated to reviewed/i, response.body

    # Update to "done"
    patch update_status_admin_feedback_submission_path(@feedback), params: { status: "done" }
    @feedback.reload
    assert_equal "done", @feedback.status
  end

  test "admin can delete feedback" do
    sign_in @admin

    feedback_id = @feedback.id

    assert_difference("FeedbackSubmission.count", -1) do
      delete admin_feedback_submission_path(@feedback)
    end

    assert_redirected_to admin_feedback_submissions_path
    follow_redirect!
    assert_match /deleted successfully/i, response.body

    # Verify feedback is gone
    assert_nil FeedbackSubmission.find_by(id: feedback_id)
  end

  test "complete admin workflow: view, filter, detail, update, delete" do
    sign_in @admin

    # 1. View all feedback
    get admin_feedback_submissions_path
    assert_response :success
    initial_count = FeedbackSubmission.count

    # 2. Filter by status
    get admin_feedback_submissions_path(status: "new")
    assert_response :success

    # 3. Click into a feedback detail
    get admin_feedback_submission_path(@feedback)
    assert_response :success
    assert_match @feedback.message, response.body

    # 4. Update status from new to reviewed
    patch update_status_admin_feedback_submission_path(@feedback), params: { status: "reviewed" }
    follow_redirect!
    assert_response :success
    @feedback.reload
    assert_equal "reviewed", @feedback.status

    # 5. Delete the feedback
    delete admin_feedback_submission_path(@feedback)
    follow_redirect!
    assert_response :success

    # 6. Verify count decreased
    get admin_feedback_submissions_path
    assert_select "tbody tr", count: initial_count - 1
  end

  test "non-admin cannot access any admin functionality" do
    sign_in @non_admin

    # Cannot access index
    get admin_feedback_submissions_path
    assert_redirected_to root_path

    # Cannot access show
    get admin_feedback_submission_path(@feedback)
    assert_redirected_to root_path

    # Cannot update status
    patch update_status_admin_feedback_submission_path(@feedback), params: { status: "reviewed" }
    assert_redirected_to root_path
    @feedback.reload
    assert_equal "new", @feedback.status # Status unchanged

    # Cannot delete
    assert_no_difference("FeedbackSubmission.count") do
      delete admin_feedback_submission_path(@feedback)
    end
    assert_redirected_to root_path
  end

  test "admin sees feedback from all users" do
    sign_in @admin

    # Create feedback from different users
    user_one_feedback = feedback_submissions(:one) # belongs to users(:one)
    user_two_feedback = feedback_submissions(:two) # belongs to users(:two)

    get admin_feedback_submissions_path
    assert_response :success

    # Both should be visible
    assert_match user_one_feedback.user.email, response.body
    assert_match user_two_feedback.user.email, response.body
  end

  test "admin status is verified via ADMIN_EMAILS environment variable" do
    sign_in @admin

    # Admin should have access
    get admin_feedback_submissions_path
    assert_response :success

    # Remove from admin list
    ENV["ADMIN_EMAILS"] = "other@example.com"

    # Should no longer have access
    get admin_feedback_submissions_path
    assert_redirected_to root_path

    # Restore admin access
    ENV["ADMIN_EMAILS"] = @admin.email

    # Should have access again
    get admin_feedback_submissions_path
    assert_response :success
  end

  test "admin can see wants_reply status and email" do
    sign_in @admin

    # Create feedback with wants_reply=true
    feedback_with_reply = feedback_submissions(:one)
    assert feedback_with_reply.wants_reply

    get admin_feedback_submission_path(feedback_with_reply)
    assert_response :success

    # Should show "Wants Reply: Yes"
    assert_select "span.badge.bg-success", text: "Yes"
    # Should show contact email
    assert_match feedback_with_reply.email, response.body
  end

  test "admin can see feedback without reply request" do
    sign_in @admin

    feedback_without_reply = feedback_submissions(:two)
    assert_not feedback_without_reply.wants_reply

    get admin_feedback_submission_path(feedback_without_reply)
    assert_response :success

    # Should show "Wants Reply: No"
    assert_select "span.badge.bg-secondary", text: "No"
  end

  test "admin can delete feedback from index page" do
    sign_in @admin

    get admin_feedback_submissions_path
    assert_response :success

    # Delete button should be present in the table
    assert_select "form[action='#{admin_feedback_submission_path(@feedback)}'][method='post']" do
      assert_select "input[name='_method'][value='delete']"
    end

    # Perform deletion from index
    assert_difference("FeedbackSubmission.count", -1) do
      delete admin_feedback_submission_path(@feedback)
    end

    assert_redirected_to admin_feedback_submissions_path
  end
end
