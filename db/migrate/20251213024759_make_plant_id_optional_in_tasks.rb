class MakePlantIdOptionalInTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tasks, :plant_id, true
  end
end
