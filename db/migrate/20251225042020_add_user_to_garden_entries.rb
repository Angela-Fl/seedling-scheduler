class AddUserToGardenEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :garden_entries, :user, null: false, foreign_key: true
  end
end
