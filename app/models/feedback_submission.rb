class FeedbackSubmission < ApplicationRecord
  belongs_to :user

  CATEGORIES = ["Bug", "Confusing/UX", "Feature request", "Performance", "Other"].freeze
  STATUSES = ["new", "reviewed", "done"].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :message, presence: true, length: { minimum: 10, maximum: 5000 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  before_validation :sanitize_user_agent

  scope :newest_first, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  def message_preview(length = 100)
    message.length > length ? "#{message[0...length]}..." : message
  end

  private

  def sanitize_user_agent
    self.user_agent = user_agent&.strip&.truncate(255)
  end
end
