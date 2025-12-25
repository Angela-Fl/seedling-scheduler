require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  include Devise::Test::IntegrationHelpers

  def setup
    super
    sign_in users(:one)
  end
end
