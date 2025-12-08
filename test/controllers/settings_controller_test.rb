require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get edit_settings_url
    assert_response :success
  end

  test "should update settings" do
    patch settings_url, params: { frost_date: "2026-06-01" }
    assert_response :redirect
  end
end
