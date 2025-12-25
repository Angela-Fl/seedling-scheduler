class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :garden_entries, dependent: :destroy
  has_many :plants, dependent: :destroy
  has_many :tasks, dependent: :destroy
end
