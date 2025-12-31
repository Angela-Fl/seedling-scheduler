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

  def task_icon_path(task_type)
    icon_map = {
      "plant_seeds" => "/images/task-icons/plant_seeds.svg",
      "begin_hardening_off" => "/images/task-icons/begin_hardening_off.svg",
      "garden_task" => "/images/task-icons/garden_task.svg",
      "plant_seedlings" => "/images/task-icons/plant_seedlings.svg"
    }
    icon_map[task_type]
  end

  def task_icon_tag(task_type, options = {})
    icon_path = task_icon_path(task_type)
    return "" unless icon_path

    size = options[:size] || "16px"
    css_class = options[:class] || ""
    image_tag(icon_path, alt: task_type, style: "width: #{size}; height: #{size}; margin-right: 4px;", class: css_class)
  end
end
