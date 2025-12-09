class ConvertToOffsetDaysInPlants < ActiveRecord::Migration[8.1]
  def up
    # Add new offset fields (integer, can be negative)
    add_column :plants, :plant_seeds_offset_days, :integer
    add_column :plants, :hardening_offset_days, :integer
    add_column :plants, :plant_seedlings_offset_days, :integer

    # Convert existing data (weeks to days, with sign)
    # Before frost = negative, after frost = positive
    execute <<-SQL
      UPDATE plants
      SET plant_seeds_offset_days = -(weeks_before_last_frost_to_start * 7)
      WHERE weeks_before_last_frost_to_start IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE plants
      SET hardening_offset_days = -(weeks_before_last_frost_to_transplant * 7)
      WHERE weeks_before_last_frost_to_transplant IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE plants
      SET plant_seedlings_offset_days = (weeks_after_last_frost_to_plant * 7)
      WHERE weeks_after_last_frost_to_plant IS NOT NULL;
    SQL

    # Remove old columns
    remove_column :plants, :weeks_before_last_frost_to_start
    remove_column :plants, :weeks_before_last_frost_to_transplant
    remove_column :plants, :weeks_after_last_frost_to_plant
  end

  def down
    # Add old columns back
    add_column :plants, :weeks_before_last_frost_to_start, :integer
    add_column :plants, :weeks_before_last_frost_to_transplant, :integer
    add_column :plants, :weeks_after_last_frost_to_plant, :integer

    # Convert data back (days to weeks, absolute values)
    execute <<-SQL
      UPDATE plants
      SET weeks_before_last_frost_to_start = ABS(plant_seeds_offset_days / 7)
      WHERE plant_seeds_offset_days < 0;
    SQL

    execute <<-SQL
      UPDATE plants
      SET weeks_before_last_frost_to_transplant = ABS(hardening_offset_days / 7)
      WHERE hardening_offset_days < 0;
    SQL

    execute <<-SQL
      UPDATE plants
      SET weeks_after_last_frost_to_plant = (plant_seedlings_offset_days / 7)
      WHERE plant_seedlings_offset_days > 0;
    SQL

    # Remove new columns
    remove_column :plants, :plant_seeds_offset_days
    remove_column :plants, :hardening_offset_days
    remove_column :plants, :plant_seedlings_offset_days
  end
end
