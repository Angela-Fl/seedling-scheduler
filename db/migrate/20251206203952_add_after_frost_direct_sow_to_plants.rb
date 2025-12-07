class AddAfterFrostDirectSowToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :weeks_after_last_frost_to_direct_sow, :integer
  end
end
