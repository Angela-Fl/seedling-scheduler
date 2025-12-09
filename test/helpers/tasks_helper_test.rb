require "test_helper"

class TasksHelperTest < ActionView::TestCase
  test "task_badge_color for plant_seeds" do
    task = Task.new(task_type: "plant_seeds")
    color = task_badge_color(task)
    assert_equal({ bg: "#FFCBE1", text: "#000000" }, color)
  end

  test "task_badge_color for begin_hardening_off" do
    task = Task.new(task_type: "begin_hardening_off")
    color = task_badge_color(task)
    assert_equal({ bg: "#F9E1A8", text: "#000000" }, color)
  end

  test "task_badge_color for plant_seedlings" do
    task = Task.new(task_type: "plant_seedlings")
    color = task_badge_color(task)
    assert_equal({ bg: "#D6E5BD", text: "#000000" }, color)
  end

  test "task_badge_color for begin_stratification" do
    task = Task.new(task_type: "begin_stratification")
    color = task_badge_color(task)
    assert_equal({ bg: "#6c757d", text: "#ffffff" }, color)
  end

  test "task_badge_color for unknown type" do
    task = Task.new
    color = task_badge_color(task)
    assert_equal({ bg: "#6c757d", text: "#ffffff" }, color)
  end
end
