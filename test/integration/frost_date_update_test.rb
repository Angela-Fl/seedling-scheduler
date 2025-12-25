require "test_helper"

class FrostDateUpdateTest < ActionDispatch::IntegrationTest
  test "updating frost date regenerates all plant tasks" do
    sign_in users(:one)
    zinnia = plants(:zinnia)
    sunflower = plants(:sunflower)

    old_zinnia_task_date = zinnia.tasks.first.due_date
    old_sunflower_task_date = sunflower.tasks.first.due_date

    new_frost_date = Date.new(2026, 6, 1)
    patch settings_path, params: { frost_date: new_frost_date.to_s }

    follow_redirect!
    assert_response :success

    zinnia.reload
    sunflower.reload

    assert_not_equal old_zinnia_task_date, zinnia.tasks.first.due_date
    assert_not_equal old_sunflower_task_date, sunflower.tasks.first.due_date
    assert_equal new_frost_date, Setting.frost_date
  end

  test "frost date change affects task list display" do
    sign_in users(:one)
    get tasks_path
    original_html = response.body

    new_frost_date = Setting.frost_date + 30.days
    patch settings_path, params: { frost_date: new_frost_date.to_s }

    get tasks_path
    updated_html = response.body

    assert_not_equal original_html, updated_html, "Task list should change after frost date update"
  end

  test "invalid frost date shows error and does not change tasks" do
    sign_in users(:one)
    original_frost_date = Setting.frost_date
    zinnia = plants(:zinnia)
    original_task_date = zinnia.tasks.first.due_date

    patch settings_path, params: { frost_date: "invalid-date" }

    assert_response :unprocessable_entity
    assert_equal original_frost_date, Setting.frost_date

    zinnia.reload
    assert_equal original_task_date, zinnia.tasks.first.due_date
  end

  test "full workflow: view settings, update frost date, verify all plants affected" do
    sign_in users(:one)
    # Step 1: View settings page
    get edit_settings_path
    assert_response :success
    assert_select "input[name='frost_date']"

    # Step 2: Check current task dates
    plant1 = plants(:zinnia)
    plant2 = plants(:sunflower)
    original_task1_date = plant1.tasks.first.due_date
    original_task2_date = plant2.tasks.first.due_date

    # Step 3: Update frost date
    new_frost_date = Date.new(2026, 7, 1)
    patch settings_path, params: { frost_date: new_frost_date.to_s }

    follow_redirect!
    assert_response :success
    assert_select ".alert-success"

    # Step 4: Verify all plants have new tasks
    plant1.reload
    plant2.reload
    new_task1_date = plant1.tasks.first.due_date
    new_task2_date = plant2.tasks.first.due_date

    assert_not_equal original_task1_date, new_task1_date, "Plant 1 tasks should have new dates"
    assert_not_equal original_task2_date, new_task2_date, "Plant 2 tasks should have new dates"

    # Step 5: View tasks page to see updated dates
    get tasks_path
    assert_response :success
  end

  test "multiple frost date updates continue to work correctly" do
    sign_in users(:one)
    plant = plants(:zinnia)

    # First update
    patch settings_path, params: { frost_date: "2026-06-01" }
    plant.reload
    first_update_date = plant.tasks.first.due_date

    # Second update
    patch settings_path, params: { frost_date: "2026-07-01" }
    plant.reload
    second_update_date = plant.tasks.first.due_date

    # Third update
    patch settings_path, params: { frost_date: "2026-05-01" }
    plant.reload
    third_update_date = plant.tasks.first.due_date

    assert_not_equal first_update_date, second_update_date
    assert_not_equal second_update_date, third_update_date
    assert_not_equal first_update_date, third_update_date
  end
end
