class AddTitleToGardenEntries < ActiveRecord::Migration[8.1]
  def up
    add_column :garden_entries, :title, :string

    # Backfill existing entries with auto-generated titles
    GardenEntry.find_each do |entry|
      formatted_date = entry.entry_date.strftime("%b %-d, %Y")
      entry.update_column(:title, "Garden Entry - #{formatted_date}")
    end
  end

  def down
    remove_column :garden_entries, :title
  end
end
