class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable
  has_many :garden_entries, dependent: :destroy
  has_many :plants, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :feedback_submissions, dependent: :destroy

  def admin?
    return false if demo?
    return false if email.blank?
    admin_emails = ENV["ADMIN_EMAILS"].to_s.split(",").map(&:strip)
    return false if admin_emails.empty?
    admin_emails.include?(email)
  end
end
