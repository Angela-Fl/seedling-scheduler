# Clear existing data in dev (safe for now)
Task.destroy_all
Plant.destroy_all

zinnia = Plant.create!(
  name: "Zinnia",
  variety: "Mixed",
  sowing_method: "indoor",
  weeks_before_last_frost_to_start: 6,
  weeks_before_last_frost_to_transplant: 1,
  weeks_after_last_frost_to_plant: 1,
  notes: "Needs warmth, hates frost."
)

snapdragon = Plant.create!(
  name: "Snapdragon",
  variety: "Tall mix",
  sowing_method: "indoor",
  weeks_before_last_frost_to_start: 10,
  weeks_before_last_frost_to_transplant: 1,
  weeks_after_last_frost_to_plant: 1,
  notes: "Cool tolerant; can go out a bit earlier."
)

sunflower = Plant.create!(
  name: "Sunflower",
  variety: "Autumn Beauty",
  sowing_method: "direct_sow",
  weeks_after_last_frost_to_plant: 1,
  notes: "Direct sow once soil is warming."
)

[sunflower, zinnia, snapdragon].each do |plant|
  plant.generate_tasks!(Setting.frost_date)
end

puts "Seeded #{Plant.count} plants and #{Task.count} tasks."
