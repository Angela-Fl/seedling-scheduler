require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # ===================
  # Validation tests
  # ===================

  test "valid task with all required attributes" do
    task = Task.new(
      plant: plants(:zinnia),
      task_type: "start",
      due_date: Date.today,
      status: "pending"
    )
    assert task.valid?
  end

  test "requires due_date" do
    task = Task.new(
      plant: plants(:zinnia),
      task_type: "start",
      status: "pending"
    )
    assert_not task.valid?
    assert_includes task.errors[:due_date], "can't be blank"
  end

  test "requires task_type" do
    task = Task.new(
      plant: plants(:zinnia),
      due_date: Date.today,
      status: "pending"
    )
    assert_not task.valid?
    assert_includes task.errors[:task_type], "can't be blank"
  end

  test "requires status" do
    task = Task.new(
      plant: plants(:zinnia),
      task_type: "start",
      due_date: Date.today
    )
    assert_not task.valid?
    assert_includes task.errors[:status], "can't be blank"
  end

  test "requires plant" do
    task = Task.new(
      task_type: "start",
      due_date: Date.today,
      status: "pending"
    )
    assert_not task.valid?
    assert_includes task.errors[:plant], "must exist"
  end

  # ===================
  # Association tests
  # ===================

  test "task belongs to plant" do
    task = tasks(:zinnia_start)
    assert_respond_to task, :plant
    assert_equal plants(:zinnia), task.plant
  end

  # ===================
  # Enum tests
  # ===================

  test "task_type enum values" do
    assert_equal %w[start harden_off plant], Task.task_types.keys
  end

  test "status enum values" do
    assert_equal %w[pending done skipped], Task.statuses.keys
  end

  # ===================
  # display_name tests
  # ===================

  test "display_name for start task" do
    task = tasks(:zinnia_start)
    assert_equal "Start seeds", task.display_name
  end

  test "display_name for harden_off task" do
    task = tasks(:zinnia_harden)
    assert_equal "Begin hardening off", task.display_name
  end

  test "display_name for plant task with indoor sowing_method" do
    task = tasks(:zinnia_plant)
    assert_equal "Plant seedlings", task.display_name
  end

  test "display_name for plant task with direct_sow sowing_method" do
    task = tasks(:sunflower_plant)
    assert_equal "Plant seeds", task.display_name
  end

  test "display_name for plant task with stratify_then_indoor" do
    plant = plants(:milkweed)
    task = Task.create!(
      plant: plant,
      task_type: "plant",
      due_date: Date.today,
      status: "pending"
    )
    assert_equal "Plant seedlings", task.display_name
  end

  # ===================
  # Status helper tests
  # ===================

  test "done! marks task as done" do
    task = tasks(:zinnia_start)
    assert_equal "pending", task.status

    task.done!

    assert_equal "done", task.reload.status
  end

  test "skip! marks task as skipped" do
    task = tasks(:zinnia_start)
    assert_equal "pending", task.status

    task.skip!

    assert_equal "skipped", task.reload.status
  end

  # ===================
  # Scope/query tests
  # ===================

  test "can query by status" do
    pending_tasks = Task.where(status: "pending")
    done_tasks = Task.where(status: "done")

    assert pending_tasks.count > 0
    assert done_tasks.count > 0
    assert_equal tasks(:completed_task), done_tasks.first
  end

  test "can query by task_type" do
    start_tasks = Task.where(task_type: "start")
    assert start_tasks.count > 0
  end
end
