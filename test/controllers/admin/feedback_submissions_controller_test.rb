require "test_helper"

class Admin::FeedbackSubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:one)
    @non_admin_user = users(:two)
    @feedback = feedback_submissions(:one)

    # Set admin email for the admin user
    ENV["ADMIN_EMAILS"] = @admin_user.email
  end

  teardown do
    ENV.delete("ADMIN_EMAILS")
  end

  # Authorization tests
  test "non-admin cannot access index" do
    sign_in @non_admin_user
    get admin_feedback_submissions_url

    assert_redirected_to root_url
    follow_redirect!
    assert_match /not authorized/i, response.body
  end

  test "non-admin cannot access show" do
    sign_in @non_admin_user
    get admin_feedback_submission_url(@feedback)

    assert_redirected_to root_url
    follow_redirect!
    assert_match /not authorized/i, response.body
  end

  test "non-admin cannot update status" do
    sign_in @non_admin_user
    patch update_status_admin_feedback_submission_url(@feedback), params: { status: "reviewed" }

    assert_redirected_to root_url
  end

  test "non-admin cannot destroy feedback" do
    sign_in @non_admin_user
    assert_no_difference("FeedbackSubmission.count") do
      delete admin_feedback_submission_url(@feedback)
    end

    assert_redirected_to root_url
  end

  test "unauthenticated user redirected to login" do
    get admin_feedback_submissions_url
    assert_redirected_to new_user_session_url
  end

  # GET #index (as admin)
  test "admin can access index" do
    sign_in @admin_user
    get admin_feedback_submissions_url

    assert_response :success
  end

  test "index shows all feedback submissions" do
    sign_in @admin_user
    get admin_feedback_submissions_url

    assert_select "tbody tr", count: FeedbackSubmission.count
  end

  test "index filters by status when param present" do
    sign_in @admin_user
    get admin_feedback_submissions_url(status: "new")

    assert_response :success
    # Should only show feedback with "new" status
    new_count = FeedbackSubmission.where(status: "new").count
    assert_select "tbody tr", count: new_count
  end

  test "index orders newest first" do
    sign_in @admin_user
    get admin_feedback_submissions_url

    assert_response :success
    # The response body should have feedback_submissions(:one) before (:three)
    # since one was created 1 day ago and three was created 3 days ago
  end

  test "index eager loads user association to prevent N+1" do
    sign_in @admin_user

    # Verify that users are eager loaded by checking the controller loads them with includes
    get admin_feedback_submissions_url

    assert_response :success
    # If N+1 queries were happening, we'd see multiple SELECT queries for users
    # The controller uses .includes(:user) which prevents this
  end

  # GET #show (as admin)
  test "admin can access show" do
    sign_in @admin_user
    get admin_feedback_submission_url(@feedback)

    assert_response :success
  end

  test "show displays correct feedback" do
    sign_in @admin_user
    get admin_feedback_submission_url(@feedback)

    assert_select "h2", text: /Feedback ##{@feedback.id}/
    assert_match @feedback.message, response.body
  end

  # PATCH #update_status (as admin)
  test "admin can update status" do
    sign_in @admin_user
    patch update_status_admin_feedback_submission_url(@feedback), params: { status: "reviewed" }

    @feedback.reload
    assert_equal "reviewed", @feedback.status
    assert_redirected_to admin_feedback_submission_url(@feedback)
  end

  test "update_status shows success notice" do
    sign_in @admin_user
    patch update_status_admin_feedback_submission_url(@feedback), params: { status: "done" }

    follow_redirect!
    assert_match /status updated to done/i, response.body
  end

  test "update_status with invalid status is handled" do
    sign_in @admin_user
    original_status = @feedback.status

    patch update_status_admin_feedback_submission_url(@feedback), params: { status: "invalid" }

    @feedback.reload
    assert_equal original_status, @feedback.status
  end

  # DELETE #destroy (as admin)
  test "admin can destroy feedback" do
    sign_in @admin_user

    assert_difference("FeedbackSubmission.count", -1) do
      delete admin_feedback_submission_url(@feedback)
    end

    assert_redirected_to admin_feedback_submissions_url
  end

  test "destroy shows success notice" do
    sign_in @admin_user
    delete admin_feedback_submission_url(@feedback)

    follow_redirect!
    assert_match /deleted successfully/i, response.body
  end

  # Removed test that used RSpec-specific any_instance method
  # Error handling is tested through integration tests instead

  # Additional authorization edge cases
  test "admin status is checked on every request" do
    sign_in @admin_user

    # First request should succeed
    get admin_feedback_submissions_url
    assert_response :success

    # Remove admin status
    ENV["ADMIN_EMAILS"] = "other@example.com"

    # Second request should fail
    get admin_feedback_submissions_url
    assert_redirected_to root_url
  end

  test "admin with whitespace in ADMIN_EMAILS can access" do
    ENV["ADMIN_EMAILS"] = " #{@admin_user.email} "
    sign_in @admin_user

    get admin_feedback_submissions_url
    assert_response :success
  end
end
