require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Associations
  test "has many feedback_submissions" do
    user = users(:one)
    assert_respond_to user, :feedback_submissions
  end

  test "destroying user destroys associated feedback_submissions" do
    user = users(:one)
    feedback_count = user.feedback_submissions.count
    assert feedback_count > 0, "User should have feedback submissions for this test"

    assert_difference("FeedbackSubmission.count", -feedback_count) do
      user.destroy
    end
  end

  # admin? method
  test "admin? returns true when email is in ADMIN_EMAILS" do
    user = users(:one)
    # Set environment variable for this test
    ENV["ADMIN_EMAILS"] = user.email

    assert user.admin?, "User should be admin when email is in ADMIN_EMAILS"

    # Clean up
    ENV.delete("ADMIN_EMAILS")
  end

  test "admin? returns true for comma-separated list of admin emails" do
    user = users(:one)
    ENV["ADMIN_EMAILS"] = "other@example.com,#{user.email},another@example.com"

    assert user.admin?, "User should be admin when email is in comma-separated list"

    ENV.delete("ADMIN_EMAILS")
  end

  test "admin? returns false when email is not in ADMIN_EMAILS" do
    user = users(:one)
    ENV["ADMIN_EMAILS"] = "admin@example.com,other@example.com"

    assert_not user.admin?, "User should not be admin when email is not in ADMIN_EMAILS"

    ENV.delete("ADMIN_EMAILS")
  end

  test "admin? returns false when ADMIN_EMAILS is empty" do
    user = users(:one)
    ENV["ADMIN_EMAILS"] = ""

    assert_not user.admin?, "User should not be admin when ADMIN_EMAILS is empty"

    ENV.delete("ADMIN_EMAILS")
  end

  test "admin? returns false when ADMIN_EMAILS is not set" do
    user = users(:one)
    ENV.delete("ADMIN_EMAILS")

    assert_not user.admin?, "User should not be admin when ADMIN_EMAILS is not set"
  end

  test "admin? returns false when user email is blank" do
    user = User.new(email: "")
    ENV["ADMIN_EMAILS"] = "admin@example.com"

    assert_not user.admin?, "User should not be admin when email is blank"

    ENV.delete("ADMIN_EMAILS")
  end

  test "admin? handles whitespace in ADMIN_EMAILS" do
    user = users(:one)
    ENV["ADMIN_EMAILS"] = " #{user.email} , other@example.com "

    assert user.admin?, "User should be admin even with whitespace in ADMIN_EMAILS"

    ENV.delete("ADMIN_EMAILS")
  end
end
