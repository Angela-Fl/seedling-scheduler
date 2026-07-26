require "test_helper"

class VersionEndpointTest < ActionDispatch::IntegrationTest
  setup do
    @original_git_sha = ENV["GIT_SHA"]
  end

  teardown do
    ENV["GIT_SHA"] = @original_git_sha
  end

  test "version is reachable without signing in" do
    get "/version"
    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "version reports the GIT_SHA baked into the image" do
    ENV["GIT_SHA"] = "0123456789abcdef0123456789abcdef01234567"

    get "/version"

    assert_equal "0123456789abcdef0123456789abcdef01234567", JSON.parse(response.body)["git_sha"]
  end

  test "version reports unknown when GIT_SHA is not set" do
    ENV.delete("GIT_SHA")

    get "/version"

    assert_response :success
    assert_equal "unknown", JSON.parse(response.body)["git_sha"]
  end
end
