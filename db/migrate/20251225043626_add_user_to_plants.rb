class AddUserToPlants < ActiveRecord::Migration[8.1]
  def change
    add_reference :plants, :user, null: true, foreign_key: true
  end
end
