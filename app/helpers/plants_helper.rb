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
      { bg: "#a2cf8f", text: "#000000" }  # Light green
    when "indoor_start"
      { bg: "#e9b38e", text: "#000000" }  # Peach/coral
    when "outdoor_start"
      { bg: "#de8ca0", text: "#000000" }  # Rose/mauve
    when "fridge_stratify"
      { bg: "#6c757d", text: "#ffffff" }  # Gray
    else
      { bg: "#6c757d", text: "#ffffff" }  # Gray
    end

    label = sowing_method.titleize.gsub("_", " ")
    content_tag(:span, label, class: "badge", style: "background-color: #{colors[:bg]}; color: #{colors[:text]}")
  end

  def format_seed_depth(depth)
    return "" if depth.blank?

    # Handle special cases
    return "Surface sow" if depth.match?(/^surface sow$/i)
    return "Surface sow (0 inches)" if depth == "0"

    # Handle fractions
    unit = depth.match?(/^[01]\/\d+$/) ? "inch" : "inches"
    "#{depth} #{unit}"
  end

  def format_plant_spacing(spacing)
    return "" if spacing.blank?
    "#{spacing} inches"
  end

  def format_days_to_sprout(days_range)
    return "" if days_range.blank?
    "#{days_range} days"
  end
end
