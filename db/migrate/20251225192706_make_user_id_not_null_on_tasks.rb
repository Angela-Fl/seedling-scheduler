class MakeUserIdNotNullOnTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tasks, :user_id, false
  end
end
