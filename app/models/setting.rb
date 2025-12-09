class Setting < ApplicationRecord
  DEFAULT_FROST_DATE = Date.new(2026, 5, 15)

  validates :key, presence: true, uniqueness: true

  def self.frost_date
    val = find_by(key: "frost_date")&.value
    val.present? ? Date.parse(val) : DEFAULT_FROST_DATE
  end

  def self.set_frost_date(date)
    setting = find_or_initialize_by(key: "frost_date")
    setting.value = date.to_s
    setting.save!
  end
end
