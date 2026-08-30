require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  include Devise::Test::IntegrationHelpers

  def setup
    super
    sign_in users(:one)

    # Every test shares one browser, and Chrome's log buffer is owned by the
    # driver rather than the page, so it outlives the session reset between
    # tests. Start each test with an empty buffer or a console assertion will
    # read whatever an earlier test happened to log as its own.
    page.driver.browser.logs.get(:browser) if page.driver.respond_to?(:browser)
  end
end
