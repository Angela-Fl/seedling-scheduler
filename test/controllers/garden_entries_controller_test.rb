require "test_helper"

class GardenEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @garden_entry = garden_entries(:one)
  end

  # Index tests
  test "should get index" do
    get garden_entries_url
    assert_response :success
  end

  test "index displays entries in correct order" do
    # Create entries with different dates
    older_entry = GardenEntry.create!(user: users(:one), title: "Older Entry", entry_date: 1.week.ago, body: "Older entry")
    newer_entry = GardenEntry.create!(user: users(:one), title: "Newer Entry", entry_date: Date.current, body: "Newer entry")

    get garden_entries_url
    assert_response :success

    # Check that entries are ordered by entry_date desc
    assert_select "div#garden_entries"
  end

  # New tests
  test "should get new" do
    get new_garden_entry_url
    assert_response :success
  end

  # Create tests
  test "should create garden_entry" do
    assert_difference("GardenEntry.count") do
      post garden_entries_url, params: { garden_entry: { title: "Test Title", body: "Test entry body", entry_date: Date.current } }
    end

    assert_redirected_to garden_entries_url
  end

  test "should create garden_entry and show success notice" do
    post garden_entries_url, params: { garden_entry: { title: "Test Title", body: "Test entry", entry_date: Date.current } }

    assert_redirected_to garden_entries_url
    follow_redirect!
    assert_select "p.text-success", text: /Garden entry was successfully created/
  end

  test "should not create garden_entry with blank body" do
    assert_no_difference("GardenEntry.count") do
      post garden_entries_url, params: { garden_entry: { title: "Valid Title", body: "", entry_date: Date.current } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create garden_entry without entry_date" do
    assert_no_difference("GardenEntry.count") do
      post garden_entries_url, params: { garden_entry: { title: "Valid Title", body: "Test body", entry_date: nil } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create garden_entry without title" do
    assert_no_difference("GardenEntry.count") do
      post garden_entries_url, params: { garden_entry: { title: "", body: "Test body", entry_date: Date.current } }
    end

    assert_response :unprocessable_entity
  end

  # Show tests
  test "should show garden_entry" do
    get garden_entry_url(@garden_entry)
    assert_response :success
  end

  # Edit tests
  test "should get edit" do
    get edit_garden_entry_url(@garden_entry)
    assert_response :success
  end

  # Update tests
  test "should update garden_entry" do
    new_body = "Updated garden entry body"
    patch garden_entry_url(@garden_entry), params: { garden_entry: { title: @garden_entry.title, body: new_body, entry_date: @garden_entry.entry_date } }

    assert_redirected_to garden_entries_url

    @garden_entry.reload
    assert_equal new_body, @garden_entry.body
  end

  test "should update garden_entry and show success notice" do
    patch garden_entry_url(@garden_entry), params: { garden_entry: { title: @garden_entry.title, body: "Updated", entry_date: @garden_entry.entry_date } }

    assert_redirected_to garden_entries_url
    follow_redirect!
    assert_select "p.text-success", text: /Garden entry was successfully updated/
  end

  test "should not update garden_entry with blank body" do
    original_body = @garden_entry.body
    patch garden_entry_url(@garden_entry), params: { garden_entry: { title: @garden_entry.title, body: "", entry_date: @garden_entry.entry_date } }

    assert_response :unprocessable_entity

    @garden_entry.reload
    assert_equal original_body, @garden_entry.body
  end

  test "should not update garden_entry with blank title" do
    original_title = @garden_entry.title
    patch garden_entry_url(@garden_entry), params: { garden_entry: { title: "", body: @garden_entry.body, entry_date: @garden_entry.entry_date } }

    assert_response :unprocessable_entity

    @garden_entry.reload
    assert_equal original_title, @garden_entry.title
  end

  test "should update entry_date" do
    new_date = 1.week.from_now.to_date
    patch garden_entry_url(@garden_entry), params: { garden_entry: { title: @garden_entry.title, body: @garden_entry.body, entry_date: new_date } }

    assert_redirected_to garden_entries_url

    @garden_entry.reload
    assert_equal new_date, @garden_entry.entry_date
  end

  # Destroy tests
  test "should destroy garden_entry" do
    assert_difference("GardenEntry.count", -1) do
      delete garden_entry_url(@garden_entry)
    end

    assert_redirected_to garden_entries_url
  end

  test "should destroy garden_entry and show success notice" do
    delete garden_entry_url(@garden_entry)

    assert_redirected_to garden_entries_url
    follow_redirect!
    assert_select "p.text-success", text: /Garden entry was successfully destroyed/
  end

  test "should return 404 for non-existent garden_entry" do
    get garden_entry_url(id: 999999)
    assert_response :not_found
  end
end
