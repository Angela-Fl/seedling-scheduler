require "application_system_test_case"

class FeedbackSubmissionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @admin = users(:one)
    ENV["ADMIN_EMAILS"] = @admin.email
  end

  teardown do
    ENV.delete("ADMIN_EMAILS")
  end

  test "user submits feedback from navbar" do
    # User is already signed in via application_system_test_case.rb
    visit tasks_path

    # Click feedback link in navbar
    click_on "Feedback"

    # Should be on feedback form
    assert_selector "h1", text: "Submit Feedback"

    # Fill in the form
    select "Bug", from: "Category"
    fill_in "Your Feedback", with: "This is a test bug report with sufficient length for validation"

    # Submit the form
    click_on "Submit Feedback"

    # Should see success message
    assert_text "Thank you for your feedback"

    # Verify feedback was created
    feedback = FeedbackSubmission.last
    assert_equal "Bug", feedback.category
    assert_match /test bug report/, feedback.message
  end

  test "wants_reply checkbox toggles email field visibility" do
    visit new_feedback_submission_path

    # Email field should be hidden initially
    assert_no_selector "input#feedback_submission_email", visible: :visible

    # Check the "I'd like a reply" checkbox
    check "I'd like a reply"

    # Give JavaScript time to execute
    sleep 1

    # Email field should now be visible
    assert_selector "input#feedback_submission_email", visible: :visible

    # Uncheck the checkbox
    uncheck "I'd like a reply"
    sleep 1

    # Email field should be hidden again
    assert_no_selector "input#feedback_submission_email", visible: :visible
  end

  test "user submits feedback with reply request" do
    visit new_feedback_submission_path

    select "Feature request", from: "Category"
    fill_in "Your Feedback", with: "I would like to request a new feature for the application"

    # Check wants reply
    check "I'd like a reply"
    sleep 1  # Wait for JavaScript

    # Email field should be visible now
    fill_in "Contact Email", with: "reply@example.com"

    click_on "Submit Feedback"

    assert_text "Thank you for your feedback"

    # Verify wants_reply was saved
    feedback = FeedbackSubmission.last
    assert feedback.wants_reply
    assert_equal "reply@example.com", feedback.email
  end

  test "form validates required fields" do
    visit new_feedback_submission_path

    # Fill in category but leave message empty (too short)
    select "Bug", from: "Category"
    fill_in "Your Feedback", with: "Short" # Less than 10 characters

    # Use JavaScript to remove HTML5 required attribute so we can test server-side validation
    page.execute_script("document.querySelector('textarea[name=\"feedback_submission[message]\"]').removeAttribute('required')")
    page.execute_script("document.querySelector('select[name=\"feedback_submission[category]\"]').removeAttribute('required')")

    click_on "Submit Feedback"

    # Should still be on the form page due to validation error
    assert_selector "h1", text: "Submit Feedback"

    # Should see error messages from Rails validation
    assert_selector "div.alert-danger"
  end

  test "form shows error for message too short" do
    visit new_feedback_submission_path

    select "Bug", from: "Category"
    fill_in "Your Feedback", with: "Short"

    # Remove HTML5 required to test server-side validation
    page.execute_script("document.querySelector('textarea[name=\"feedback_submission[message]\"]').removeAttribute('required')")
    page.execute_script("document.querySelector('select[name=\"feedback_submission[category]\"]').removeAttribute('required')")

    click_on "Submit Feedback"

    # Should show validation error
    assert_selector "div.alert-danger"
    assert_text "too short"
  end

  test "admin can view and manage feedback" do
    # Create some feedback first
    FeedbackSubmission.create!(
      user: @user,
      category: "Bug",
      message: "System test feedback that should appear in admin panel",
      status: "new"
    )

    visit admin_feedback_submissions_path

    # Should see feedback list
    assert_selector "h1", text: "Feedback Submissions"
    assert_text "System test feedback"

    # Click view button
    click_on "View", match: :first

    # Should be on detail page
    assert_text "System test feedback that should appear in admin panel"

    # Update status - accept the confirmation dialog
    accept_confirm do
      click_on "Reviewed"
    end

    # Should see success message
    assert_text "Status updated to reviewed"
  end

  test "admin can filter feedback by status" do
    visit admin_feedback_submissions_path

    # Click on "New" filter
    click_on "New"

    # Should only see new feedback
    new_count = FeedbackSubmission.where(status: "new").count
    assert_selector "tbody tr", count: new_count

    # Click on "Done" filter
    click_on "Done"

    # Should only see done feedback
    done_count = FeedbackSubmission.where(status: "done").count
    assert_selector "tbody tr", count: done_count
  end

  test "admin can delete feedback" do
    feedback = FeedbackSubmission.create!(
      user: @user,
      category: "Other",
      message: "Feedback to be deleted in system test",
      status: "new"
    )

    visit admin_feedback_submission_path(feedback)

    # Click delete button and confirm
    accept_confirm do
      click_on "Delete Feedback"
    end

    # Should redirect to index
    assert_selector "h1", text: "Feedback Submissions"
    assert_text "deleted successfully"

    # Feedback should be gone
    assert_not FeedbackSubmission.exists?(feedback.id)
  end

  test "non-admin cannot access admin panel" do
    ENV["ADMIN_EMAILS"] = "other@example.com" # Remove admin access

    visit admin_feedback_submissions_path

    # Should be redirected
    assert_text "You are not authorized"
    assert_no_selector "h1", text: "Feedback Submissions"
  end

  test "feedback form captures page source" do
    # Visit from tasks page
    visit tasks_path
    click_on "Feedback"

    select "Performance", from: "Category"
    fill_in "Your Feedback", with: "The tasks page is slow to load"

    click_on "Submit Feedback"

    feedback = FeedbackSubmission.last
    assert_match /tasks/, feedback.page
  end

  test "cancel button returns to previous page" do
    visit tasks_path
    click_on "Feedback"

    assert_selector "h1", text: "Submit Feedback"

    click_on "Cancel"

    # Should return to tasks page
    assert_selector "h1", text: /tasks/i
  end

  test "email field pre-fills with user email" do
    visit new_feedback_submission_path

    check "I'd like a reply"
    sleep 1  # Wait for JavaScript to show the field

    # Email field should be pre-filled with user's email
    assert_field "Contact Email", with: @user.email
  end
end
