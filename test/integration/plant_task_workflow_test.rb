require "test_helper"

class PlantTaskWorkflowTest < ActionDispatch::IntegrationTest
  test "creating indoor start plant generates all three task types" do
    sign_in users(:one)
    get new_plant_path
    assert_response :success

    assert_difference("Plant.count", 1) do
      assert_difference("Task.count", 3) do
        post plants_path, params: {
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
    end

    follow_redirect!
    assert_response :success

    plant = Plant.last
    assert_equal 3, plant.tasks.count
    assert plant.tasks.exists?(task_type: "plant_seeds")
    assert plant.tasks.exists?(task_type: "begin_hardening_off")
    assert plant.tasks.exists?(task_type: "plant_seedlings")
  end

  test "creating direct sow plant generates only plant_seeds task" do
    sign_in users(:one)
    assert_difference("Plant.count", 1) do
      assert_difference("Task.count", 1) do
        post plants_path, params: {
        plant: {
          name: "Test Carrot",
          sowing_method: "direct_sow",
          plant_seeds_weeks: "2",
          plant_seeds_unit: "weeks",
          plant_seeds_direction: "after"
        }
      }
      end
    end

    plant = Plant.last
    assert_equal 1, plant.tasks.count
    assert plant.tasks.exists?(task_type: "plant_seeds")
    assert_not plant.tasks.exists?(task_type: "begin_hardening_off")
  end

  test "editing plant regenerates tasks with new dates" do
    sign_in users(:one)
    plant = plants(:zinnia)
    original_task_ids = plant.tasks.pluck(:id)

    patch plant_path(plant), params: {
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

    follow_redirect!
    plant.reload
    new_task_ids = plant.tasks.pluck(:id)

    assert_not_equal original_task_ids.sort, new_task_ids.sort
    assert_equal -56, plant.plant_seeds_offset_days
  end

  test "deleting plant removes from plant list and task list" do
    sign_in users(:one)
    plant = plants(:zinnia)
    task_count = plant.tasks.count

    get plants_path
    assert_select "a", text: plant.name

    get tasks_path
    assert_select "td", text: /#{plant.name}/

    assert_difference("Plant.count", -1) do
      assert_difference("Task.count", -task_count) do
        delete plant_path(plant)
      end
    end

    follow_redirect!
    assert_select "a", text: plant.name, count: 0
  end

  test "full workflow: create plant, view tasks, edit plant, see updated tasks" do
    sign_in users(:one)
    # Step 1: Create a new plant
    post plants_path, params: {
      plant: {
        name: "Workflow Test Plant",
        variety: "Test Variety",
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

    plant = Plant.last
    assert_equal "Workflow Test Plant", plant.name
    assert_equal 3, plant.tasks.count

    # Step 2: View the plant page
    get plant_path(plant)
    assert_response :success
    assert_select "h1", text: "Workflow Test Plant"

    # Step 3: View the tasks index
    get tasks_path
    assert_response :success
    assert_select "td", text: /Workflow Test Plant/

    # Step 4: Edit the plant with new timing
    patch plant_path(plant), params: {
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

    # Step 5: Verify tasks were regenerated
    plant.reload
    assert_equal -56, plant.plant_seeds_offset_days
    assert_equal 3, plant.tasks.count

    # Step 6: View tasks again to see updated dates
    get tasks_path
    assert_response :success
  end
end
