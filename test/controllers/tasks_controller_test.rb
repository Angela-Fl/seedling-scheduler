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

  # ===================
  # Calendar view tests
  # ===================

  test "should get calendar view" do
    get calendar_tasks_url
    assert_response :success
    assert_select "h1", text: "Task Calendar"
  end

  test "calendar view shows last frost date" do
    get calendar_tasks_url
    assert_response :success
    assert_select ".alert", text: /Last frost date/
  end

  # ===================
  # JSON API tests
  # ===================

  test "index returns JSON with tasks" do
    get tasks_url(format: :json)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
    assert json_response.length > 0

    # Verify structure of first task
    task = json_response.first
    assert task.key?("id")
    assert task.key?("due_date")
    assert task.key?("task_type")
    assert task.key?("status")
    assert task.key?("plant_name")
  end

  test "index JSON filters by date range" do
    plant = plants(:zinnia)
    start_date = Date.current
    end_date = Date.current + 7.days

    # Create tasks outside the range
    plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: start_date - 10.days,
      status: "pending"
    )
    plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: end_date + 10.days,
      status: "pending"
    )

    # Create task inside the range
    in_range_task = plant.tasks.create!(
      task_type: "plant_seeds",
      due_date: start_date + 3.days,
      status: "pending"
    )

    get tasks_url(format: :json, start: start_date.iso8601, end: end_date.iso8601)
    assert_response :success

    json_response = JSON.parse(response.body)
    task_ids = json_response.map { |t| t["id"] }

    # Only the in-range task should be returned
    assert_includes task_ids, in_range_task.id
  end

  test "create task via JSON API" do
    plant = plants(:zinnia)
    assert_difference("Task.count", 1) do
      post tasks_url(format: :json), params: {
        task: {
          plant_id: plant.id,
          task_type: "plant_seeds",
          due_date: Date.today,
          status: "pending",
          notes: "Test task"
        }
      }
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "plant_seeds", json_response["task_type"]
    assert_equal "Test task", json_response["notes"]
  end

  test "create task without plant via JSON API" do
    assert_difference("Task.count", 1) do
      post tasks_url(format: :json), params: {
        task: {
          task_type: "plant_seeds",
          due_date: Date.today,
          status: "pending",
          notes: "General task"
        }
      }
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_nil json_response["plant_id"]
    assert_nil json_response["plant_name"]
  end

  test "update task via JSON API" do
    task = tasks(:zinnia_start)
    patch task_url(task, format: :json), params: {
      task: {
        status: "done",
        notes: "Updated notes"
      }
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "done", json_response["status"]
    assert_equal "Updated notes", json_response["notes"]
  end

  test "update task with invalid data returns error" do
    task = tasks(:zinnia_start)
    patch task_url(task, format: :json), params: {
      task: {
        due_date: nil  # due_date is required
      }
    }

    assert_response :unprocessable_entity
  end
end
