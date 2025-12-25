module TasksHelper
  def task_badge_color(task)
    case task.task_type
    when "plant_seeds"
      { bg: "#FFCBE1", text: "#000000" }  # Light pink for planting seeds
    when "observe_sprouts"
      { bg: "#E8D4F1", text: "#000000" }  # Light purple for observation
    when "begin_hardening_off"
      { bg: "#F9E1A8", text: "#000000" }  # Light yellow for hardening
    when "plant_seedlings"
      { bg: "#D6E5BD", text: "#000000" }  # Light green for transplanting seedlings
    when "garden_task"
      { bg: "#C9E4F5", text: "#000000" }  # Light blue for general garden tasks
    else
      { bg: "#6c757d", text: "#ffffff" }  # Gray for other tasks
    end
  end
end
