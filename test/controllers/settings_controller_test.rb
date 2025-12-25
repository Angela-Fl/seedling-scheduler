require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should get edit" do
    get edit_settings_url
    assert_response :success
  end

  test "should update settings with valid date" do
    new_date = "2025-06-01"
    patch settings_url, params: { frost_date: new_date }

    assert_redirected_to edit_settings_url
    assert_equal Date.parse(new_date), Setting.frost_date
    follow_redirect!
    assert_select ".alert-success", text: /Frost date updated/
  end

  test "should regenerate all plant tasks on update" do
    plant = plants(:zinnia)
    original_task_ids = plant.tasks.pluck(:id)

    patch settings_url, params: { frost_date: "2025-07-01" }

    plant.reload
    new_task_ids = plant.tasks.pluck(:id)

    # Tasks should be regenerated (different IDs)
    assert_not_equal original_task_ids.sort, new_task_ids.sort
  end

  test "should show error with invalid date format" do
    original_frost_date = Setting.frost_date

    patch settings_url, params: { frost_date: "invalid-date-format" }

    assert_response :unprocessable_entity
    assert_equal original_frost_date, Setting.frost_date
    assert_select ".alert-danger", text: /Invalid date format/
  end

  test "should render edit template on invalid date" do
    patch settings_url, params: { frost_date: "not-a-date" }

    assert_response :unprocessable_entity
    # Verify it re-renders the edit form
    assert_select "form"
    assert_select "input[name='frost_date']"
  end

  test "should show error with empty date" do
    patch settings_url, params: { frost_date: "" }

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "should not regenerate tasks on invalid date" do
    plant = plants(:zinnia)
    original_task_ids = plant.tasks.pluck(:id)

    patch settings_url, params: { frost_date: "invalid" }

    plant.reload
    current_task_ids = plant.tasks.pluck(:id)

    # Tasks should NOT be regenerated
    assert_equal original_task_ids.sort, current_task_ids.sort
  end
end
