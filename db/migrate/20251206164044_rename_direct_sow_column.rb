class RenameDirectSowColumn < ActiveRecord::Migration[8.1]
  def change
    rename_column :plants, :weeks_after_last_frost_to_direct_sow, :weeks_after_last_frost_to_plant
  end
end
