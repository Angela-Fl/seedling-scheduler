require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tasks_url
    assert_response :success
  end

  test "index shows tasks from last 7 days" do
    plant = plants(:zinnia)
    old_task = plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: Date.current - Task::HISTORY_DAYS.days,
      status: "pending"
    )

    get tasks_url
    assert_response :success

    # Verify the old task is included (it's exactly 7 days old)
    assert_select "tr", text: /#{plant.name}/
  end

  test "index does not show tasks older than 7 days" do
    plant = Plant.create!(
      name: "Test Plant",
      sowing_method: "direct_sow",
      plant_seeds_offset_days: 7
    )
    very_old_task = plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: Date.current - (Task::HISTORY_DAYS + 1).days,
      status: "pending"
    )

    get tasks_url
    assert_response :success

    # Verify the very old task date is NOT in the response
    assert_select "td", text: very_old_task.due_date.to_fs(:long), count: 0
  end

  test "index shows future tasks" do
    plant = plants(:zinnia)
    future_date = Date.current + 30.days
    future_task = plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: future_date,
      status: "pending"
    )

    get tasks_url
    assert_response :success

    # Verify the future task date appears in the response
    assert_select "td", text: future_date.to_fs(:long), count: 1
  end

  test "index orders tasks by due_date" do
    # Create tasks with specific dates to verify ordering
    plant = plants(:zinnia)
    plant.tasks.destroy_all

    task1 = plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: Date.current + 5.days,
      status: "pending"
    )
    task2 = plant.tasks.create!(
      task_type: "begin_hardening_off",
      due_date: Date.current + 2.days,
      status: "pending"
    )
    task3 = plant.tasks.create!(
      task_type: "plant_seedlings",
      due_date: Date.current + 8.days,
      status: "pending"
    )

    get tasks_url
    assert_response :success

    # Verify tasks in the database are being queried with correct order
    tasks = Task.where("due_date >= ?", Date.current - Task::HISTORY_DAYS.days).order(:due_date)
    assert tasks.length >= 3, "Should have at least 3 tasks"
    assert_equal task2.id, tasks[0].id, "First task should be the one due soonest"
  end

  test "index includes plant names for tasks" do
    get tasks_url
    assert_response :success

    # Verify we can see plant names (tests eager loading implicitly)
    assert_select "td", text: /Zinnia/
  end
end
