class Task < ApplicationRecord
  HISTORY_DAYS = 7

  belongs_to :plant, optional: true

  enum :task_type, {
    plant_seeds: "plant_seeds",
    begin_hardening_off: "begin_hardening_off",
    plant_seedlings: "plant_seedlings",
    begin_stratification: "begin_stratification"  # Not used yet, placeholder
  }, prefix: :task

  enum :status, {
    pending: "pending",
    done: "done",
    skipped: "skipped"
  }, prefix: true

  # Validations
  validates :due_date, presence: true
  validates :task_type, presence: true
  validates :status, presence: true

  # Returns human-friendly label based on task type
  def display_name
    case task_type
    when "plant_seeds"
      "Plant seeds"
    when "begin_hardening_off"
      "Begin hardening off"
    when "plant_seedlings"
      "Plant seedlings"
    when "begin_stratification"
      "Begin fridge stratification"
    else
      task_type.humanize
    end
  end

  def done!
    update!(status: "done")
  end

  def skip!
    update!(status: "skipped")
  end

  # Returns task description with plant name if available
  def display_subject
    if plant
      "#{plant.name}#{plant.variety ? " (#{plant.variety})" : ''} - #{display_name}"
    else
      display_name  # Just task type for general tasks
    end
  end
end
