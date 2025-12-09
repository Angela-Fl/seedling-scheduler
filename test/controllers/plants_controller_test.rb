require "test_helper"

class PlantsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get plants_url
    assert_response :success
  end

  test "should get show" do
    plant = plants(:zinnia)
    get plant_url(plant)
    assert_response :success
  end

  test "should get new" do
    get new_plant_url
    assert_response :success
  end

  test "should get edit" do
    plant = plants(:zinnia)
    get edit_plant_url(plant)
    assert_response :success
  end

  test "should create plant with valid params" do
    assert_difference("Plant.count", 1) do
      post plants_url, params: {
        plant: {
          name: "Test Tomato",
          variety: "Cherry",
          sowing_method: "indoor_start",
          plant_seeds_weeks: "6",
          plant_seeds_unit: "weeks",
          plant_seeds_direction: "before",
          hardening_weeks: "1",
          hardening_unit: "weeks",
          hardening_direction: "before",
          plant_seedlings_weeks: "1",
          plant_seedlings_unit: "weeks",
          plant_seedlings_direction: "after"
        }
      }
    end

    assert_redirected_to plant_url(Plant.last)
    assert_equal "Test Tomato", Plant.last.name
    assert_equal -42, Plant.last.plant_seeds_offset_days
  end

  test "should generate tasks on create" do
    assert_difference("Task.count", 3) do
      post plants_url, params: {
        plant: {
          name: "Test Plant",
          sowing_method: "indoor_start",
          plant_seeds_weeks: "6",
          plant_seeds_unit: "weeks",
          plant_seeds_direction: "before",
          hardening_weeks: "1",
          hardening_unit: "weeks",
          hardening_direction: "before",
          plant_seedlings_weeks: "1",
          plant_seedlings_unit: "weeks",
          plant_seedlings_direction: "after"
        }
      }
    end
  end

  test "should not create plant with invalid params" do
    assert_no_difference("Plant.count") do
      post plants_url, params: {
        plant: {
          name: "",  # Invalid - name is required
          sowing_method: "indoor_start"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update plant with valid params" do
    plant = plants(:zinnia)
    patch plant_url(plant), params: {
      plant: {
        name: "Updated Zinnia",
        plant_seeds_weeks: "8",
        plant_seeds_unit: "weeks",
        plant_seeds_direction: "before",
        hardening_weeks: "1",
        hardening_unit: "weeks",
        hardening_direction: "before",
        plant_seedlings_weeks: "1",
        plant_seedlings_unit: "weeks",
        plant_seedlings_direction: "after"
      }
    }

    assert_redirected_to plant_url(plant)
    plant.reload
    assert_equal "Updated Zinnia", plant.name
    assert_equal -56, plant.plant_seeds_offset_days
  end

  test "should regenerate tasks on update" do
    plant = plants(:zinnia)
    original_task_count = plant.tasks.count

    patch plant_url(plant), params: {
      plant: {
        plant_seeds_weeks: "8",
        plant_seeds_unit: "weeks",
        plant_seeds_direction: "before",
        hardening_weeks: "1",
        hardening_unit: "weeks",
        hardening_direction: "before",
        plant_seedlings_weeks: "1",
        plant_seedlings_unit: "weeks",
        plant_seedlings_direction: "after"
      }
    }

    plant.reload
    assert_equal original_task_count, plant.tasks.count
  end

  test "should not update plant with invalid params" do
    plant = plants(:zinnia)
    original_name = plant.name

    patch plant_url(plant), params: {
      plant: {
        name: ""  # Invalid - name is required
      }
    }

    assert_response :unprocessable_entity
    plant.reload
    assert_equal original_name, plant.name
  end

  test "should destroy plant" do
    plant = plants(:zinnia)

    assert_difference("Plant.count", -1) do
      delete plant_url(plant)
    end

    assert_redirected_to plants_url
  end

  test "should destroy associated tasks when destroying plant" do
    plant = plants(:zinnia)
    task_count = plant.tasks.count

    assert task_count > 0, "Plant should have tasks"

    assert_difference("Task.count", -task_count) do
      delete plant_url(plant)
    end
  end

  test "should regenerate tasks via regenerate_tasks action" do
    plant = plants(:zinnia)
    original_task_ids = plant.tasks.pluck(:id)

    post regenerate_tasks_plant_url(plant)

    assert_redirected_to plant_url(plant)
    plant.reload
    new_task_ids = plant.tasks.pluck(:id)

    # Task IDs should be different (new tasks created)
    assert_not_equal original_task_ids.sort, new_task_ids.sort
  end

  test "convert_offset_param converts weeks to days correctly" do
    post plants_url, params: {
      plant: {
        name: "Test",
        sowing_method: "direct_sow",
        plant_seeds_weeks: "2",
        plant_seeds_unit: "weeks",
        plant_seeds_direction: "after"
      }
    }

    plant = Plant.last
    assert_equal 14, plant.plant_seeds_offset_days
  end

  test "convert_offset_param handles days unit correctly" do
    post plants_url, params: {
      plant: {
        name: "Test",
        sowing_method: "direct_sow",
        plant_seeds_weeks: "10",
        plant_seeds_unit: "days",
        plant_seeds_direction: "after"
      }
    }

    plant = Plant.last
    assert_equal 10, plant.plant_seeds_offset_days
  end

  test "convert_offset_param handles before direction correctly" do
    post plants_url, params: {
      plant: {
        name: "Test",
        sowing_method: "direct_sow",
        plant_seeds_weeks: "2",
        plant_seeds_unit: "weeks",
        plant_seeds_direction: "before"
      }
    }

    plant = Plant.last
    assert_equal -14, plant.plant_seeds_offset_days
  end

  test "convert_offset_param handles after direction correctly" do
    post plants_url, params: {
      plant: {
        name: "Test",
        sowing_method: "direct_sow",
        plant_seeds_weeks: "3",
        plant_seeds_unit: "weeks",
        plant_seeds_direction: "after"
      }
    }

    plant = Plant.last
    assert_equal 21, plant.plant_seeds_offset_days
  end
end
