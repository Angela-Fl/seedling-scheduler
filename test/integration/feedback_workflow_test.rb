require "test_helper"

class FeedbackWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "user submits feedback successfully" do
    sign_in @user

    # Navigate to feedback form
    get new_feedback_submission_path(from: "/tasks")
    assert_response :success

    # Submit feedback
    assert_difference("FeedbackSubmission.count", 1) do
      post feedback_submissions_path, params: {
        feedback_submission: {
          category: "Bug",
          message: "This is a test bug report with enough characters",
          page: "/tasks"
        }
      }
    end

    # Should redirect to root
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    # Should show success message
    assert_match /thank you for your feedback/i, response.body

    # Verify feedback was created correctly
    feedback = FeedbackSubmission.last
    assert_equal @user, feedback.user
    assert_equal "Bug", feedback.category
    assert_equal "This is a test bug report with enough characters", feedback.message
    assert_equal "/tasks", feedback.page
    assert_equal "new", feedback.status
    assert_not feedback.wants_reply
  end

  test "user submits feedback with wants_reply" do
    sign_in @user

    assert_difference("FeedbackSubmission.count", 1) do
      post feedback_submissions_path, params: {
        feedback_submission: {
          category: "Feature request",
          message: "I would like a new feature with this description",
          wants_reply: true,
          email: "custom@example.com"
        }
      }
    end

    feedback = FeedbackSubmission.last
    assert feedback.wants_reply
    assert_equal "custom@example.com", feedback.email
  end

  test "user cannot submit feedback without authentication" do
    # Don't sign in
    get new_feedback_submission_path
    assert_redirected_to new_user_session_path
  end

  test "user cannot submit invalid feedback" do
    sign_in @user

    assert_no_difference("FeedbackSubmission.count") do
      post feedback_submissions_path, params: {
        feedback_submission: {
          category: "",
          message: "Short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "user can submit feedback from any page with correct from parameter" do
    sign_in @user

    # Test from different pages
    [ "/plants", "/tasks", "/calendar", "/settings" ].each do |from_path|
      get new_feedback_submission_path(from: from_path)
      assert_response :success

      # Verify the from parameter is captured
      assert_select "input[type=hidden][name='feedback_submission[page]'][value='#{from_path}']"
    end
  end

  test "user feedback auto-captures user agent" do
    sign_in @user

    post feedback_submissions_path,
         params: {
           feedback_submission: {
             category: "Performance",
             message: "App is slow on mobile browsers"
           }
         },
         headers: { "HTTP_USER_AGENT" => "MobileApp/2.0" }

    feedback = FeedbackSubmission.last
    assert_equal "MobileApp/2.0", feedback.user_agent
  end

  test "multiple users can submit feedback independently" do
    user_one = users(:one)
    user_two = users(:two)

    # User one submits feedback
    sign_in user_one
    post feedback_submissions_path, params: {
      feedback_submission: {
        category: "Bug",
        message: "User one's feedback message here"
      }
    }
    feedback_one = FeedbackSubmission.last
    sign_out user_one

    # User two submits feedback
    sign_in user_two
    post feedback_submissions_path, params: {
      feedback_submission: {
        category: "Feature request",
        message: "User two's feature request goes here"
      }
    }
    feedback_two = FeedbackSubmission.last

    # Verify each feedback belongs to the correct user
    assert_equal user_one, feedback_one.user
    assert_equal user_two, feedback_two.user
    assert_not_equal feedback_one.user, feedback_two.user
  end

  test "complete feedback workflow from navbar click to submission" do
    sign_in @user

    # Start from tasks page
    get tasks_path
    assert_response :success

    # Click feedback link in navbar (simulated with direct navigation with from param)
    get new_feedback_submission_path(from: tasks_path)
    assert_response :success
    assert_select "h1", "Submit Feedback"

    # Fill and submit form
    assert_difference("FeedbackSubmission.count", 1) do
      post feedback_submissions_path, params: {
        feedback_submission: {
          category: "Confusing/UX",
          message: "The interface could be clearer in this area",
          page: tasks_path,
          wants_reply: false
        }
      }
    end

    # Verify redirect and success
    assert_redirected_to root_path
    follow_redirect!
    assert_match /thank you/i, response.body

    # Verify data
    feedback = FeedbackSubmission.last
    assert_equal "Confusing/UX", feedback.category
    assert_equal tasks_path, feedback.page
    assert_not feedback.wants_reply
  end
end
