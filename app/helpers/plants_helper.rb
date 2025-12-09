module PlantsHelper
  def format_offset(offset_days)
    return "" if offset_days.nil?

    abs_days = offset_days.abs
    direction = offset_days < 0 ? "before frost" : "after frost"

    # Convert to weeks if divisible by 7
    if abs_days % 7 == 0
      weeks = abs_days / 7
      "#{weeks} #{'week'.pluralize(weeks)} #{direction}"
    else
      "#{abs_days} #{'day'.pluralize(abs_days)} #{direction}"
    end
  end
end
