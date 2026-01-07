# Set up frost date
Setting.set_frost_date(Date.new(2026, 5, 15))
puts "Set frost date to #{Setting.frost_date.to_fs(:long)}"

# Create demo user
puts "\nCreating demo user..."
demo_user = User.find_or_initialize_by(email: "demo@seedlingscheduler.com")
demo_user.assign_attributes(
  password: SecureRandom.hex(32),
  demo: true,
  confirmed_at: Time.current,
  created_at: 1.month.ago
)
demo_user.save!(validate: false)
puts "Demo user: #{demo_user.email}"

# Clear existing demo data for clean state
demo_user.plants.destroy_all
demo_user.garden_entries.destroy_all

puts "Creating demo plants..."

# Indoor start plants (8 weeks before to 3 weeks after frost)
tomato = demo_user.plants.create!(
  name: "Tomato", variety: "Brandywine",
  sowing_method: "indoor_start",
  plant_seeds_offset_days: -56, hardening_offset_days: -7,
  plant_seedlings_offset_days: 14,
  days_to_sprout: "7-14", seed_depth: "1/4", plant_spacing: "24-36",
  notes: "Heirloom variety. Start indoors 8 weeks before frost. Needs warmth and full sun."
)

basil = demo_user.plants.create!(
  name: "Basil", variety: "Genovese",
  sowing_method: "indoor_start",
  plant_seeds_offset_days: -42, hardening_offset_days: -7,
  plant_seedlings_offset_days: 21,
  days_to_sprout: "5-10", seed_depth: "1/4", plant_spacing: "10-12",
  notes: "Very frost sensitive. Wait until soil is warm. Plant near tomatoes."
)

pepper = demo_user.plants.create!(
  name: "Pepper", variety: "California Wonder Bell",
  sowing_method: "indoor_start",
  plant_seeds_offset_days: -63, hardening_offset_days: -7,
  plant_seedlings_offset_days: 14,
  days_to_sprout: "10-21", seed_depth: "1/4", plant_spacing: "18-24",
  notes: "Slow to germinate. Needs consistent warmth. Great for fresh eating."
)

# Direct sow plants
zinnia = demo_user.plants.create!(
  name: "Zinnia", variety: "Benary's Giant Mix",
  sowing_method: "direct_sow",
  plant_seeds_offset_days: 7,
  days_to_sprout: "7-10", seed_depth: "1/4", plant_spacing: "12-18",
  notes: "Easy flower for cutting. Blooms all summer. Attracts butterflies."
)

lettuce = demo_user.plants.create!(
  name: "Lettuce", variety: "Mixed Greens",
  sowing_method: "direct_sow",
  plant_seeds_offset_days: -14,
  days_to_sprout: "7-14", seed_depth: "1/4", plant_spacing: "6-8",
  notes: "Cool season crop. Can plant before frost. Succession plant every 2 weeks."
)

zucchini = demo_user.plants.create!(
  name: "Zucchini", variety: "Black Beauty",
  sowing_method: "direct_sow",
  plant_seeds_offset_days: 14,
  days_to_sprout: "7-10", seed_depth: "1/2", plant_spacing: "36-48",
  notes: "Prolific producer! Needs lots of space. Check daily when fruiting."
)

sunflower = demo_user.plants.create!(
  name: "Sunflower", variety: "Mammoth",
  sowing_method: "direct_sow",
  plant_seeds_offset_days: 7,
  days_to_sprout: "7-14", seed_depth: "1/2", plant_spacing: "18-24",
  notes: "Full sun. Tall variety needs support. Birds love the seeds!"
)

# Outdoor start (winter sowing)
milkweed = demo_user.plants.create!(
  name: "Milkweed", variety: "Common Milkweed",
  sowing_method: "outdoor_start",
  plant_seeds_offset_days: -28, plant_seedlings_offset_days: 21,
  days_to_sprout: "14-21", seed_depth: "surface sow", plant_spacing: "18-24",
  notes: "Native plant for monarchs. Use winter sowing method in milk jugs."
)

plants = [tomato, basil, pepper, zinnia, lettuce, zucchini, sunflower, milkweed]

# Generate tasks
puts "Generating tasks..."
plants.each do |plant|
  plant.generate_tasks!(Setting.frost_date)
  puts "  - #{plant.name}: #{plant.tasks.count} tasks"
end

# Mark past tasks as complete
demo_user.tasks.where("due_date < ?", Date.current).limit(5).each(&:done!)

# Create journal entries
puts "Creating journal entries..."
demo_user.garden_entries.create!(
  title: "Spring Planning Session",
  entry_date: 1.month.ago.to_date,
  body: "Planning garden layout today. Trying Three Sisters method this year!\n\nRemember to rotate crops - tomatoes in a new bed."
)

demo_user.garden_entries.create!(
  title: "Seed Starting Day",
  entry_date: 2.weeks.ago.to_date,
  body: "Started tomatoes and peppers under lights. Using heat mat for peppers (75°F).\n\nLabeled everything this time!"
)

demo_user.garden_entries.create!(
  title: "First Sprouts!",
  entry_date: 1.week.ago.to_date,
  body: "Tomatoes are up! Still waiting on peppers.\n\nBottom watering prevents damping off."
)

puts "\nSeed data complete!"
puts "Plants: #{demo_user.plants.count} | Tasks: #{demo_user.tasks.count} | Entries: #{demo_user.garden_entries.count}"
