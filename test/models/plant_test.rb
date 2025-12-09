require "test_helper"

class PlantTest < ActiveSupport::TestCase
  # ===================
  # Validation tests
  # ===================

  test "valid plant with all attributes" do
    plant = Plant.new(
      name: "Tomato",
      variety: "Cherry",
      sowing_method: "indoor_start",
      plant_seeds_offset_days: -42,
      hardening_offset_days: -7,
      plant_seedlings_offset_days: 7
    )
    assert plant.valid?
  end

  test "requires name" do
    plant = Plant.new(sowing_method: "direct_sow", plant_seeds_offset_days: 7)
    assert_not plant.valid?
    assert_includes plant.errors[:name], "can't be blank"
  end

  test "requires sowing_method" do
    plant = Plant.new(name: "Tomato")
    assert_not plant.valid?
    assert_includes plant.errors[:sowing_method], "can't be blank"
  end

  test "indoor_start plants require plant_seeds_offset_days" do
    plant = Plant.new(
      name: "Tomato",
      sowing_method: "indoor_start",
      plant_seedlings_offset_days: 7
    )
    assert_not plant.valid?
    assert_includes plant.errors[:base], "Please fill out the 'Plant seeds' field"
  end

  test "fridge_stratify plants require plant_seeds_offset_days" do
    plant = Plant.new(
      name: "Milkweed",
      sowing_method: "fridge_stratify",
      plant_seedlings_offset_days: 7
    )
    assert_not plant.valid?
    assert_includes plant.errors[:base], "Please fill out the 'Plant seeds' field"
  end

  test "outdoor_start plants require plant_seeds_offset_days" do
    plant = Plant.new(
      name: "Echinacea",
      sowing_method: "outdoor_start",
      plant_seedlings_offset_days: 7
    )
    assert_not plant.valid?
    assert_includes plant.errors[:base], "Please fill out the 'Plant seeds' field"
  end

  test "all plants require plant_seeds_offset_days" do
    plant = Plant.new(
      name: "Sunflower",
      sowing_method: "direct_sow"
    )
    assert_not plant.valid?
    assert_includes plant.errors[:base], "Please fill out the 'Plant seeds' field"
  end

  test "direct_sow plants are valid with plant_seeds_offset_days" do
    plant = Plant.new(
      name: "Sunflower",
      sowing_method: "direct_sow",
      plant_seeds_offset_days: 7
    )
    assert plant.valid?
  end

  test "offset values can be negative integers" do
    plant = Plant.new(
      name: "Tomato",
      sowing_method: "indoor_start",
      plant_seeds_offset_days: -42,
      plant_seedlings_offset_days: 7
    )
    assert plant.valid?
  end

  # ===================
  # Association tests
  # ===================

  test "plant has many tasks" do
    plant = plants(:zinnia)
    assert_respond_to plant, :tasks
    assert plant.tasks.count > 0
  end

  test "destroying plant destroys associated tasks" do
    plant = plants(:zinnia)
    task_count = plant.tasks.count
    assert task_count > 0

    assert_difference "Task.count", -task_count do
      plant.destroy
    end
  end

  # ===================
  # generate_tasks! tests
  # ===================

  test "generate_tasks! creates plant_seeds task for indoor plant" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    start_task = plant.tasks.find_by(task_type: "plant_seeds")
    assert_not_nil start_task
    assert_equal last_frost - 42.days, start_task.due_date
    assert_equal "pending", start_task.status
  end

  test "generate_tasks! creates begin_hardening_off task for indoor plant" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    harden_task = plant.tasks.find_by(task_type: "begin_hardening_off")
    assert_not_nil harden_task
    assert_equal last_frost - 7.days, harden_task.due_date
  end

  test "generate_tasks! creates plant_seedlings task" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    plant_task = plant.tasks.find_by(task_type: "plant_seedlings")
    assert_not_nil plant_task
    assert_equal last_frost + 7.days, plant_task.due_date
  end

  test "generate_tasks! does not create hardening or seedlings tasks for direct_sow plants" do
    plant = plants(:sunflower)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    assert_nil plant.tasks.find_by(task_type: "begin_hardening_off")
    assert_nil plant.tasks.find_by(task_type: "plant_seedlings")
    assert_not_nil plant.tasks.find_by(task_type: "plant_seeds")
  end

  test "generate_tasks! creates plant_seeds task for outdoor_start plants" do
    plant = Plant.create!(
      name: "Echinacea",
      sowing_method: "outdoor_start",
      plant_seeds_offset_days: -70,
      plant_seedlings_offset_days: 7
    )
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    start_task = plant.tasks.find_by(task_type: "plant_seeds")
    assert_not_nil start_task
    assert_equal last_frost - 70.days, start_task.due_date
  end

  test "generate_tasks! does not create hardening task for outdoor_start plants" do
    plant = Plant.create!(
      name: "Echinacea",
      sowing_method: "outdoor_start",
      plant_seeds_offset_days: -70,
      plant_seedlings_offset_days: 7
    )
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    assert_nil plant.tasks.find_by(task_type: "begin_hardening_off")
    assert_not_nil plant.tasks.find_by(task_type: "plant_seeds")
    assert_not_nil plant.tasks.find_by(task_type: "plant_seedlings")
  end

  test "generate_tasks! clears existing tasks before creating new ones" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    # Generate twice
    plant.generate_tasks!(last_frost)
    initial_count = plant.tasks.count

    plant.generate_tasks!(last_frost)

    assert_equal initial_count, plant.tasks.count
  end

  # ===================
  # Enum tests
  # ===================

  test "sowing_method enum values" do
    assert_equal %w[indoor_start direct_sow outdoor_start fridge_stratify], Plant.sowing_methods.keys
  end
end
