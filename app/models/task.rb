class Task < ApplicationRecord
  belongs_to :plant

  enum :task_type, {
    start: "start",
    harden_off: "harden_off",
    plant: "plant"
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

  # Returns human-friendly label based on task type and plant's sowing method
  def display_name
    case task_type
    when "start"
      "Start indoors"
    when "harden_off"
      "Begin hardening off"
    when "plant"
      case plant.sowing_method
      when "indoor"
        "Plant seedlings"
      when "direct_sow"
        "Plant seeds"
      when "winter_sow"
        "Plant out winter-sown seedlings"
      when "stratify_then_indoor"
        "Plant seedlings"
      else
        "Plant"
      end
    else
      task_type&.humanize || "Unknown"
    end
  end

  def done!
    update!(status: "done")
  end

  def skip!
    update!(status: "skipped")
  end
end
