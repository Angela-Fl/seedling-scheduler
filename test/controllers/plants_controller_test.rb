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
end
