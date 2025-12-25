class MakeUserIdNotNullOnPlants < ActiveRecord::Migration[8.1]
  def change
    change_column_null :plants, :user_id, false
  end
end
