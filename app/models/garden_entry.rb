class GardenEntry < ApplicationRecord
  validates :entry_date, presence: true
  validates :body, presence: true
  belongs_to :user
end
