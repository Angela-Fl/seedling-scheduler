require "application_system_test_case"

class GardenEntriesTest < ApplicationSystemTestCase
  setup do
    sign_in users(:one)
    @garden_entry = garden_entries(:one)
  end

  test "visiting the index" do
    visit garden_entries_path

    assert_selector "h1", text: "Garden Journal"
    assert_text @garden_entry.title
  end

  test "creating a new garden entry with title" do
    visit garden_entries_path

    click_on "New journal entry"

    fill_in "Title", with: "My First Garden Entry"
    fill_in "Entry date", with: Date.current
    fill_in "Body", with: "This is the body of my first garden entry."

    click_on "Create Garden entry"

    assert_text "Garden entry was successfully created"
    assert_text "My First Garden Entry"
  end

  test "title is required in the form" do
    visit new_garden_entry_path

    # Leave title blank
    fill_in "Entry date", with: Date.current
    fill_in "Body", with: "Body without a title"

    click_on "Create Garden entry"

    assert_text "Title can't be blank"
  end

  test "editing an existing entry's title" do
    visit garden_entries_path

    # Click the first "Edit" link
    click_on "Edit", match: :first

    fill_in "Title", with: "Updated Title"
    click_on "Update Garden entry"

    assert_text "Garden entry was successfully updated"
    assert_text "Updated Title"
  end

  test "title appears in the list view" do
    # Create a distinctive entry
    entry = GardenEntry.create!(
      user: users(:one),
      title: "Distinctive Garden Entry Title",
      entry_date: Date.current,
      body: "This entry has a distinctive title"
    )

    visit garden_entries_path

    # Title should be visible and styled as a heading
    assert_selector "h4", text: "Distinctive Garden Entry Title"
  end

  test "deleting a garden entry" do
    visit garden_entries_path

    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Garden entry was successfully destroyed"
  end
end
