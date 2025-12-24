class CreateGardenEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :garden_entries do |t|
      t.date :entry_date
      t.text :body

      t.timestamps
    end
  end
end
