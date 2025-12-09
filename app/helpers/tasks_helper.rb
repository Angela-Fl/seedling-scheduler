module TasksHelper
  def task_badge_color(task)
    case task.task_type
    when "plant_seeds"
      "success"  # Green for planting seeds
    when "begin_hardening_off"
      "blue"  # Deep blue for hardening
    when "plant_seedlings"
      "pink"  # Watermelon pink for transplanting seedlings
    else
      "secondary"  # Gray for other tasks
    end
  end
end
