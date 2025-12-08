class Plant < ApplicationRecord
  has_many :tasks, dependent: :destroy

  # How you start this plant
  enum :sowing_method, {
    indoor: "indoor",
    direct_sow: "direct_sow",
    winter_sow: "winter_sow",
    stratify_then_indoor: "stratify_then_indoor"
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :sowing_method, presence: true
  validates :weeks_before_last_frost_to_start,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :weeks_before_last_frost_to_transplant,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :weeks_after_last_frost_to_plant,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  # Indoor plants should have start weeks defined
  validate :indoor_plants_have_start_weeks, if: -> { sowing_method.in?(%w[indoor stratify_then_indoor winter_sow]) }

  # All plants should have weeks_after_last_frost_to_plant defined
  validate :plants_have_plant_weeks

  def generate_tasks!(last_frost_date)
    tasks.destroy_all

    # START indoors or winter sowing (for indoor/stratify/winter_sow methods)
    if weeks_before_last_frost_to_start.present?
      tasks.create!(
        task_type: "start",
        due_date: last_frost_date - weeks_before_last_frost_to_start.weeks,
        status: "pending"
      )
    end

    # HARDEN OFF (for seedlings before planting out)
    if weeks_before_last_frost_to_transplant.present? && sowing_method.in?(%w[indoor stratify_then_indoor])
      tasks.create!(
        task_type: "harden_off",
        due_date: last_frost_date - weeks_before_last_frost_to_transplant.weeks,
        status: "pending"
      )
    end

    # PLANT - unified task (seeds or seedlings depending on sowing_method)
    if weeks_after_last_frost_to_plant.present?
      tasks.create!(
        task_type: "plant",
        due_date: last_frost_date + weeks_after_last_frost_to_plant.weeks,
        status: "pending"
      )
    end
  end

  private

  def indoor_plants_have_start_weeks
    if weeks_before_last_frost_to_start.blank?
      errors.add(:weeks_before_last_frost_to_start, "is required for this sowing method")
    end
  end

  def plants_have_plant_weeks
    if weeks_after_last_frost_to_plant.blank?
      errors.add(:weeks_after_last_frost_to_plant, "is required for all plants")
    end
  end
end
