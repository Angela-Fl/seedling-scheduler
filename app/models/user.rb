class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable
  has_many :garden_entries, dependent: :destroy
  has_many :plants, dependent: :destroy
  has_many :tasks, dependent: :destroy
end
