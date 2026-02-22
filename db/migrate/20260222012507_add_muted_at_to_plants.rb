class AddMutedAtToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :muted_at, :datetime
    add_index :plants, :muted_at
  end
end
