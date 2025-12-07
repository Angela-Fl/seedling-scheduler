class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants do |t|
      t.string :name
      t.string :variety
      t.string :sowing_method
      t.integer :weeks_before_last_frost_to_start
      t.integer :weeks_before_last_frost_to_transplant
      t.text :notes

      t.timestamps
    end
  end
end
