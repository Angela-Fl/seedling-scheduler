require "test_helper"

class FeedbackSubmissionTest < ActiveSupport::TestCase
  # Validations
  test "requires category" do
    feedback = FeedbackSubmission.new(
      message: "Test message that is long enough",
      user: users(:one)
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:category], "can't be blank"
  end

  test "category must be in CATEGORIES list" do
    feedback = FeedbackSubmission.new(
      category: "Invalid Category",
      message: "Test message that is long enough",
      user: users(:one)
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:category], "is not included in the list"
  end

  test "accepts valid category" do
    FeedbackSubmission::CATEGORIES.each do |category|
      feedback = FeedbackSubmission.new(
        category: category,
        message: "Test message that is long enough",
        user: users(:one)
      )
      assert feedback.valid?, "#{category} should be a valid category"
    end
  end

  test "requires message" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      user: users(:one)
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:message], "can't be blank"
  end

  test "message must be at least 10 characters" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Too short",
      user: users(:one)
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:message], "is too short (minimum is 10 characters)"
  end

  test "message with exactly 10 characters is valid" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "1234567890",
      user: users(:one)
    )
    assert feedback.valid?
  end

  test "message must not exceed 5000 characters" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "a" * 5001,
      user: users(:one)
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:message], "is too long (maximum is 5000 characters)"
  end

  test "message with exactly 5000 characters is valid" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "a" * 5000,
      user: users(:one)
    )
    assert feedback.valid?
  end

  test "requires status" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one)
    )
    feedback.status = nil
    assert_not feedback.valid?
    assert_includes feedback.errors[:status], "can't be blank"
  end

  test "status must be in STATUSES list" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      status: "invalid_status"
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:status], "is not included in the list"
  end

  test "email format validation accepts valid email" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      email: "test@example.com"
    )
    assert feedback.valid?
  end

  test "email format validation rejects invalid email" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      email: "not-an-email"
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:email], "is invalid"
  end

  test "email can be blank" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      email: ""
    )
    assert feedback.valid?
  end

  test "requires user" do
    feedback = FeedbackSubmission.new(
      category: "Bug",
      message: "Test message that is long enough"
    )
    assert_not feedback.valid?
    assert_includes feedback.errors[:user], "must exist"
  end

  # Defaults
  test "status defaults to new" do
    feedback = FeedbackSubmission.new
    assert_equal "new", feedback.status
  end

  test "wants_reply defaults to false" do
    feedback = FeedbackSubmission.new
    assert_equal false, feedback.wants_reply
  end

  # Associations
  test "belongs to user" do
    feedback = feedback_submissions(:one)
    assert_instance_of User, feedback.user
    assert_equal users(:one), feedback.user
  end

  # Scopes
  test "newest_first orders by created_at DESC" do
    feedbacks = FeedbackSubmission.newest_first
    assert_equal feedback_submissions(:one), feedbacks.first
    assert_equal feedback_submissions(:three), feedbacks.last
  end

  test "by_status filters by status when present" do
    feedbacks = FeedbackSubmission.by_status("new")
    assert_includes feedbacks, feedback_submissions(:one)
    assert_not_includes feedbacks, feedback_submissions(:two)
    assert_not_includes feedbacks, feedback_submissions(:three)
  end

  test "by_status returns all when status is blank" do
    feedbacks = FeedbackSubmission.by_status("")
    assert_equal FeedbackSubmission.all.to_a, feedbacks.to_a
  end

  test "by_status returns all when status is nil" do
    feedbacks = FeedbackSubmission.by_status(nil)
    assert_equal FeedbackSubmission.all.to_a, feedbacks.to_a
  end

  # Instance Methods
  test "message_preview truncates long message" do
    long_message = "a" * 150
    feedback = FeedbackSubmission.new(message: long_message)
    preview = feedback.message_preview(100)
    assert_equal 103, preview.length # 100 chars + "..."
    assert preview.ends_with?("...")
  end

  test "message_preview returns full message when shorter than length" do
    short_message = "Short message"
    feedback = FeedbackSubmission.new(message: short_message)
    preview = feedback.message_preview(100)
    assert_equal short_message, preview
  end

  test "sanitize_user_agent strips whitespace" do
    feedback = FeedbackSubmission.create!(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      user_agent: "  Mozilla/5.0  "
    )
    assert_equal "Mozilla/5.0", feedback.user_agent
  end

  test "sanitize_user_agent truncates to 255 characters" do
    long_agent = "a" * 300
    feedback = FeedbackSubmission.create!(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      user_agent: long_agent
    )
    assert_equal 255, feedback.user_agent.length
  end

  test "sanitize_user_agent handles nil" do
    feedback = FeedbackSubmission.create!(
      category: "Bug",
      message: "Test message that is long enough",
      user: users(:one),
      user_agent: nil
    )
    assert_nil feedback.user_agent
  end
end
