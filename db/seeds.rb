# Clear existing data
Task.destroy_all
Plant.destroy_all
Setting.destroy_all

# Set up frost date
Setting.set_frost_date(Date.new(2026, 5, 15))

# Create sample plants with current schema
zinnia = Plant.create!(
  name: "Zinnia",
  variety: "Mixed",
  sowing_method: "indoor_start",
  plant_seeds_offset_days: -42,    # 6 weeks before frost
  hardening_offset_days: -7,       # 1 week before frost
  plant_seedlings_offset_days: 7,  # 1 week after frost
  notes: "Needs warmth, hates frost."
)

snapdragon = Plant.create!(
  name: "Snapdragon",
  variety: "Tall mix",
  sowing_method: "indoor_start",
  plant_seeds_offset_days: -70,    # 10 weeks before frost
  hardening_offset_days: -7,       # 1 week before frost
  plant_seedlings_offset_days: 7,  # 1 week after frost
  notes: "Cool tolerant; can go out earlier."
)

sunflower = Plant.create!(
  name: "Sunflower",
  variety: "Autumn Beauty",
  sowing_method: "direct_sow",
  plant_seeds_offset_days: 7,      # 1 week after frost
  notes: "Direct sow once soil is warming."
)

milkweed = Plant.create!(
  name: "Common Milkweed",
  variety: "Asclepias syriaca",
  sowing_method: "outdoor_start",
  plant_seeds_offset_days: -14,     # 2 weeks before frost (winter sowing)
  plant_seedlings_offset_days: 14,  # 2 weeks after frost
  notes: "Native plant, requires cold stratification. Use outdoor winter sowing method."
)

# Generate tasks for all plants
[ zinnia, snapdragon, sunflower, milkweed ].each do |plant|
  plant.generate_tasks!(Setting.frost_date)
end

puts "Seeded #{Plant.count} plants and #{Task.count} tasks with frost date #{Setting.frost_date.to_fs(:long)}"
