module TasksHelper
  def task_badge_color(task)
    case task.task_type
    when "plant_seeds"
      { bg: "#FFCBE1", text: "#000000" }  # Purple for planting seeds
    when "begin_hardening_off"
      { bg: "#F9E1A8", text: "#000000" }  # Burgundy for hardening
    when "plant_seedlings"
      { bg: "#D6E5BD", text: "#000000" }  # Dark magenta for transplanting seedlings
    else
      { bg: "#6c757d", text: "#ffffff" }  # Gray for other tasks
    end
  end
end
