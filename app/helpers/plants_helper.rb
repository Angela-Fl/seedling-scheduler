module PlantsHelper
  def format_offset(offset_days)
    return "" if offset_days.nil?

    abs_days = offset_days.abs
    direction = offset_days < 0 ? "before frost" : "after frost"

    # Convert to weeks if divisible by 7
    if abs_days % Plant::DAYS_PER_WEEK == 0
      weeks = abs_days / Plant::DAYS_PER_WEEK
      "#{weeks} #{'week'.pluralize(weeks)} #{direction}"
    else
      "#{abs_days} #{'day'.pluralize(abs_days)} #{direction}"
    end
  end

  def sowing_method_badge(sowing_method)
    colors = case sowing_method
    when "direct_sow"
      { bg: "#a2cf8f", text: "#000000" }  # Orange
    when "indoor_start"
      { bg: "#e9b38e", text: "#000000" }  # Teal
    when "outdoor_start"
      { bg: "#de8ca0", text: "#000000" }  # Purple
    when "fridge_stratify"
      { bg: "#6c757d", text: "#ffffff" }  # Gray
    else
      { bg: "#6c757d", text: "#ffffff" }  # Gray
    end

    label = sowing_method.titleize.gsub("_", " ")
    content_tag(:span, label, class: "badge", style: "background-color: #{colors[:bg]}; color: #{colors[:text]}")
  end
end
