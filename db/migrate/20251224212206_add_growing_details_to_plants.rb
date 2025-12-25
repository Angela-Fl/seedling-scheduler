class AddGrowingDetailsToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :days_to_sprout, :string
    add_column :plants, :seed_depth, :string
    add_column :plants, :plant_spacing, :string
  end
end
