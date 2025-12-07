require "test_helper"

class PlantTest < ActiveSupport::TestCase
  # ===================
  # Validation tests
  # ===================

  test "valid plant with all attributes" do
    plant = Plant.new(
      name: "Tomato",
      variety: "Cherry",
      sowing_method: "indoor",
      weeks_before_last_frost_to_start: 6,
      weeks_before_last_frost_to_transplant: 1,
      weeks_after_last_frost_to_plant: 1
    )
    assert plant.valid?
  end

  test "requires name" do
    plant = Plant.new(sowing_method: "direct_sow", weeks_after_last_frost_to_plant: 1)
    assert_not plant.valid?
    assert_includes plant.errors[:name], "can't be blank"
  end

  test "requires sowing_method" do
    plant = Plant.new(name: "Tomato")
    assert_not plant.valid?
    assert_includes plant.errors[:sowing_method], "can't be blank"
  end

  test "indoor plants require weeks_before_last_frost_to_start" do
    plant = Plant.new(
      name: "Tomato",
      sowing_method: "indoor",
      weeks_after_last_frost_to_plant: 1
    )
    assert_not plant.valid?
    assert_includes plant.errors[:weeks_before_last_frost_to_start], "is required for indoor sowing methods"
  end

  test "stratify_then_indoor plants require weeks_before_last_frost_to_start" do
    plant = Plant.new(
      name: "Milkweed",
      sowing_method: "stratify_then_indoor",
      weeks_after_last_frost_to_plant: 1
    )
    assert_not plant.valid?
    assert_includes plant.errors[:weeks_before_last_frost_to_start], "is required for indoor sowing methods"
  end

  test "direct_sow plants require weeks_after_last_frost_to_plant" do
    plant = Plant.new(
      name: "Sunflower",
      sowing_method: "direct_sow"
    )
    assert_not plant.valid?
    assert_includes plant.errors[:weeks_after_last_frost_to_plant], "is required for direct sow plants"
  end

  test "direct_sow plants are valid with weeks_after_last_frost_to_plant" do
    plant = Plant.new(
      name: "Sunflower",
      sowing_method: "direct_sow",
      weeks_after_last_frost_to_plant: 1
    )
    assert plant.valid?
  end

  test "week values must be non-negative integers" do
    plant = Plant.new(
      name: "Tomato",
      sowing_method: "indoor",
      weeks_before_last_frost_to_start: -1
    )
    assert_not plant.valid?
    assert_includes plant.errors[:weeks_before_last_frost_to_start], "must be greater than or equal to 0"
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

  test "generate_tasks! creates start task for indoor plant" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    start_task = plant.tasks.find_by(task_type: "start")
    assert_not_nil start_task
    assert_equal last_frost - 6.weeks, start_task.due_date
    assert_equal "pending", start_task.status
  end

  test "generate_tasks! creates harden_off task for indoor plant" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    harden_task = plant.tasks.find_by(task_type: "harden_off")
    assert_not_nil harden_task
    assert_equal last_frost - 1.week, harden_task.due_date
  end

  test "generate_tasks! creates plant task" do
    plant = plants(:zinnia)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    plant_task = plant.tasks.find_by(task_type: "plant")
    assert_not_nil plant_task
    assert_equal last_frost + 1.week, plant_task.due_date
  end

  test "generate_tasks! does not create harden_off for direct_sow plants" do
    plant = plants(:sunflower)
    last_frost = Date.new(2026, 5, 5)

    plant.generate_tasks!(last_frost)

    assert_nil plant.tasks.find_by(task_type: "harden_off")
    assert_nil plant.tasks.find_by(task_type: "start")
    assert_not_nil plant.tasks.find_by(task_type: "plant")
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
    assert_equal %w[indoor direct_sow winter_sow stratify_then_indoor], Plant.sowing_methods.keys
  end
end
