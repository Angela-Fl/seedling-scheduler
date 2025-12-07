class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.frost_date
    val = find_by(key: "frost_date")&.value
    val.present? ? Date.parse(val) : Date.new(2026, 5, 15)
  end

  def self.set_frost_date(date)
    setting = find_or_initialize_by(key: "frost_date")
    setting.value = date.to_s
    setting.save!
  end
end
