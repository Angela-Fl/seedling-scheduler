class Plant < ApplicationRecord
  DAYS_PER_WEEK = 7

  has_many :tasks, dependent: :destroy

  # How you start this plant
  enum :sowing_method, {
    indoor_start: "indoor_start",
    direct_sow: "direct_sow",
    outdoor_start: "outdoor_start",
    fridge_stratify: "fridge_stratify"  # Hidden from UI, placeholder for future
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :sowing_method, presence: true
  validates :plant_seeds_offset_days, numericality: { only_integer: true }, allow_nil: true
  validates :hardening_offset_days, numericality: { only_integer: true }, allow_nil: true
  validates :plant_seedlings_offset_days, numericality: { only_integer: true }, allow_nil: true

  validate :all_plants_must_have_plant_seeds_offset
  validate :transplanting_methods_need_plant_seedlings_offset

  def generate_tasks!(last_frost_date)
    # Clear existing tasks
    tasks.destroy_all

    # PLANT_SEEDS task: Universal first task for all sowing methods
    if plant_seeds_offset_days.present?
      tasks.create!(
        task_type: :plant_seeds,
        due_date: last_frost_date + plant_seeds_offset_days.days,
        notes: sowing_method_direct_sow? ? "Plant #{name} seeds outdoors" : "Sow seeds for #{name} (#{variety})",
        status: :pending
      )
    end

    # BEGIN_HARDENING_OFF task: only for indoor_start
    if sowing_method_indoor_start? && hardening_offset_days.present?
      tasks.create!(
        task_type: :begin_hardening_off,
        due_date: last_frost_date + hardening_offset_days.days,
        notes: "Begin hardening off #{name} seedlings",
        status: :pending
      )
    end

    # PLANT_SEEDLINGS task: for indoor_start and outdoor_start (not direct_sow)
    if !sowing_method_direct_sow? && plant_seedlings_offset_days.present?
      tasks.create!(
        task_type: :plant_seedlings,
        due_date: last_frost_date + plant_seedlings_offset_days.days,
        notes: "Transplant #{name} seedlings",
        status: :pending
      )
    end
  end

  private

  def all_plants_must_have_plant_seeds_offset
    if plant_seeds_offset_days.blank?
      errors.add(:base, "Please fill out the 'Plant seeds' field")
    end
  end

  def transplanting_methods_need_plant_seedlings_offset
    if !sowing_method_direct_sow? && plant_seedlings_offset_days.blank?
      errors.add(:base, "Please fill out the 'Transplant seedlings' field for this sowing method")
    end
  end
end
