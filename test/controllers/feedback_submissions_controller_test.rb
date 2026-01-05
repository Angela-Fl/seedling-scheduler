require "test_helper"

class FeedbackSubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  # GET #new
  test "should get new when logged in" do
    get new_feedback_submission_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    sign_out users(:one)
    get new_feedback_submission_url
    assert_redirected_to new_user_session_url
  end

  # Note: assigns() is not available in Rails 8+ without additional gems
  # These tests verify behavior through response inspection instead

  # POST #create
  test "should create feedback with valid params" do
    assert_difference("FeedbackSubmission.count", 1) do
      post feedback_submissions_url, params: {
        feedback_submission: {
          category: "Bug",
          message: "This is a test feedback message",
          wants_reply: true,
          email: "test@example.com"
        }
      }
    end

    assert_redirected_to root_url
    follow_redirect!
    assert_match /thank you for your feedback/i, response.body
  end

  test "should not create feedback without category" do
    assert_no_difference("FeedbackSubmission.count") do
      post feedback_submissions_url, params: {
        feedback_submission: {
          message: "This is a test feedback message"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create feedback with message too short" do
    assert_no_difference("FeedbackSubmission.count") do
      post feedback_submissions_url, params: {
        feedback_submission: {
          category: "Bug",
          message: "Too short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "created feedback belongs to current_user" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message"
      }
    }

    feedback = FeedbackSubmission.last
    assert_equal users(:one), feedback.user
  end

  test "auto-captures page from params" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message",
        page: "/plants"
      }
    }

    feedback = FeedbackSubmission.last
    assert_equal "/plants", feedback.page
  end

  test "auto-captures user_agent from request" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message"
      }
    }, headers: { "HTTP_USER_AGENT" => "TestBrowser/1.0" }

    feedback = FeedbackSubmission.last
    assert_equal "TestBrowser/1.0", feedback.user_agent
  end

  test "does not permit user_id in params" do
    other_user = users(:two)

    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message",
        user_id: other_user.id
      }
    }

    feedback = FeedbackSubmission.last
    assert_equal users(:one), feedback.user
    assert_not_equal other_user, feedback.user
  end

  test "does not permit status in params" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message",
        status: "done"
      }
    }

    feedback = FeedbackSubmission.last
    assert_equal "new", feedback.status
  end

  test "permits wants_reply in params" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message",
        wants_reply: true
      }
    }

    feedback = FeedbackSubmission.last
    assert feedback.wants_reply
  end

  test "permits email in params" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "Bug",
        message: "This is a test feedback message",
        email: "custom@example.com"
      }
    }

    feedback = FeedbackSubmission.last
    assert_equal "custom@example.com", feedback.email
  end

  test "re-renders form with errors on validation failure" do
    post feedback_submissions_url, params: {
      feedback_submission: {
        category: "",
        message: "Short"
      }
    }

    assert_response :unprocessable_entity
    assert_select "div.alert-danger", text: /error/i
  end

  # Removed test that used assigns() - behavior is tested through other means
end
