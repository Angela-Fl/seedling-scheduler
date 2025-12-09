class UpdateSowingMethodAndTaskTypeEnums < ActiveRecord::Migration[8.1]
  def up
    # Update sowing_method enum values in plants table
    execute "UPDATE plants SET sowing_method = 'indoor_start' WHERE sowing_method = 'indoor';"
    execute "UPDATE plants SET sowing_method = 'outdoor_start' WHERE sowing_method = 'winter_sow';"
    execute "UPDATE plants SET sowing_method = 'fridge_stratify' WHERE sowing_method = 'stratify_then_indoor';"

    # Update task_type enum values in tasks table
    execute "UPDATE tasks SET task_type = 'plant_seeds' WHERE task_type = 'start';"
    execute "UPDATE tasks SET task_type = 'begin_hardening_off' WHERE task_type = 'harden_off';"
    execute "UPDATE tasks SET task_type = 'plant_seedlings' WHERE task_type = 'plant';"
  end

  def down
    # Reverse the changes
    execute "UPDATE plants SET sowing_method = 'indoor' WHERE sowing_method = 'indoor_start';"
    execute "UPDATE plants SET sowing_method = 'winter_sow' WHERE sowing_method = 'outdoor_start';"
    execute "UPDATE plants SET sowing_method = 'stratify_then_indoor' WHERE sowing_method = 'fridge_stratify';"

    execute "UPDATE tasks SET task_type = 'start' WHERE task_type = 'plant_seeds';"
    execute "UPDATE tasks SET task_type = 'harden_off' WHERE task_type = 'begin_hardening_off';"
    execute "UPDATE tasks SET task_type = 'plant' WHERE task_type = 'plant_seedlings';"
  end
end
