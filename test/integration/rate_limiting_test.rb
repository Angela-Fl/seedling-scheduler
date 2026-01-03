require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  # Disable parallel execution for rate limiting tests to avoid cache conflicts
  parallelize(workers: 1)

  setup do
    @user = users(:one)
    @password = "password123456"
    # Clear Rack::Attack cache before each test
    Rack::Attack.cache.store.clear
  end

  # =============================================================================
  # Login Throttling (5 attempts / 20 seconds / email)
  # =============================================================================

  test "allows 5 login attempts within 20 seconds" do
    5.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
      assert_response :unprocessable_entity, "Should allow first 5 login attempts (returns 422 for invalid login)"
    end
  end

  test "throttles login attempts after 5 requests in 20 seconds" do
    # Make 5 requests (at the limit)
    5.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
    end

    # 6th request should be throttled
    post user_session_path, params: {
      user: { email: @user.email, password: "wrongpassword" }
    }
    assert_response :too_many_requests  # 429
    assert response.headers["Retry-After"].present?, "Should include Retry-After header"
  end

  test "login throttling is case-insensitive for email" do
    # Clear cache to avoid interference from previous tests
    Rack::Attack.cache.store.clear

    # Make 3 requests with lowercase email
    3.times do
      post user_session_path, params: {
        user: { email: @user.email.downcase, password: "wrongpassword" }
      }
    end

    # Make 2 requests with uppercase email (should count towards same limit)
    2.times do
      post user_session_path, params: {
        user: { email: @user.email.upcase, password: "wrongpassword" }
      }
    end

    # 6th request should be throttled (regardless of case)
    post user_session_path, params: {
      user: { email: @user.email.capitalize, password: "wrongpassword" }
    }
    assert_response :too_many_requests
  end

  test "login throttling is per email not per IP" do
    # Clear cache first
    Rack::Attack.cache.store.clear

    # Make 5 requests for user one
    5.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
    end

    # User one should be throttled
    post user_session_path, params: {
      user: { email: @user.email, password: "wrongpassword" }
    }
    assert_response :too_many_requests

    # But user two should still be able to log in from same IP
    user_two = users(:two)
    post user_session_path, params: {
      user: { email: user_two.email, password: @password }
    }
    assert_response :redirect, "Different email should not be throttled"
  end

  # =============================================================================
  # Password Reset Throttling (3 attempts / 5 minutes / email)
  # =============================================================================

  test "allows 3 password reset requests within 5 minutes" do
    3.times do
      post user_password_path, params: {
        user: { email: @user.email }
      }
      assert_response :redirect, "Should allow first 3 password reset requests"
    end
  end

  test "throttles password reset after 3 requests in 5 minutes" do
    # Make 3 requests
    3.times do
      post user_password_path, params: {
        user: { email: @user.email }
      }
    end

    # 4th request should be throttled
    post user_password_path, params: {
      user: { email: @user.email }
    }
    assert_response :too_many_requests
    assert response.headers["Retry-After"].present?
  end

  test "password reset throttling is case-insensitive" do
    # Mix of uppercase and lowercase should count towards same limit
    post user_password_path, params: {
      user: { email: @user.email.downcase }
    }

    post user_password_path, params: {
      user: { email: @user.email.upcase }
    }

    post user_password_path, params: {
      user: { email: @user.email.capitalize }
    }

    # 4th request should be throttled
    post user_password_path, params: {
      user: { email: @user.email }
    }
    assert_response :too_many_requests
  end

  # =============================================================================
  # Registration Throttling (5 attempts / hour / IP)
  # =============================================================================

  test "allows 5 registration attempts per hour from same IP" do
    5.times do |i|
      post user_registration_path, params: {
        user: {
          email: "newuser#{i}@example.com",
          password: "password123456",
          password_confirmation: "password123456"
        }
      }
      assert_response :redirect, "Should allow first 5 registration attempts"
    end
  end

  test "throttles registration after 5 attempts per hour from same IP" do
    # Make 5 registrations
    5.times do |i|
      post user_registration_path, params: {
        user: {
          email: "newuser#{i}@example.com",
          password: "password123456",
          password_confirmation: "password123456"
        }
      }
    end

    # 6th request should be throttled
    post user_registration_path, params: {
      user: {
        email: "newuser6@example.com",
        password: "password123456",
        password_confirmation: "password123456"
      }
    }
    assert_response :too_many_requests
  end

  # =============================================================================
  # Unlock Instructions Throttling (3 attempts / 5 minutes / email)
  # =============================================================================

  test "allows 3 unlock instruction requests within 5 minutes" do
    @user.lock_access!

    3.times do
      post user_unlock_path, params: {
        user: { email: @user.email }
      }
      assert_response :redirect, "Should allow first 3 unlock requests"
    end
  end

  test "throttles unlock instructions after 3 requests in 5 minutes" do
    @user.lock_access!

    3.times do
      post user_unlock_path, params: {
        user: { email: @user.email }
      }
    end

    # 4th request should be throttled
    post user_unlock_path, params: {
      user: { email: @user.email }
    }
    assert_response :too_many_requests
  end

  # =============================================================================
  # Confirmation Email Throttling (3 attempts / 5 minutes / email)
  # =============================================================================

  test "allows 3 confirmation email requests within 5 minutes" do
    unconfirmed_user = User.create!(
      email: "unconfirmed@example.com",
      password: "password123456",
      password_confirmation: "password123456"
    )

    3.times do
      post user_confirmation_path, params: {
        user: { email: unconfirmed_user.email }
      }
      assert_response :redirect, "Should allow first 3 confirmation requests"
    end
  end

  test "throttles confirmation emails after 3 requests in 5 minutes" do
    unconfirmed_user = User.create!(
      email: "unconfirmed2@example.com",
      password: "password123456",
      password_confirmation: "password123456"
    )

    3.times do
      post user_confirmation_path, params: {
        user: { email: unconfirmed_user.email }
      }
    end

    # 4th request should be throttled
    post user_confirmation_path, params: {
      user: { email: unconfirmed_user.email }
    }
    assert_response :too_many_requests
  end

  # =============================================================================
  # General Request Throttling (100 requests / minute / IP)
  # =============================================================================

  test "allows 100 general requests per minute" do
    sign_in @user

    100.times do
      get root_path
      assert_response :success, "Should allow first 100 requests"
    end
  end

  test "throttles general requests after 100 per minute" do
    sign_in @user

    # Make 100 requests
    100.times do
      get root_path
    end

    # 101st request should be throttled
    get root_path
    assert_response :too_many_requests
    assert response.headers["Retry-After"].present?
  end

  test "asset requests are excluded from general throttle" do
    # Simulate 150 asset requests (should not be throttled)
    # Note: This test assumes assets would normally exceed the limit

    # In a real scenario, asset requests don't go through Rails routing
    # This is a conceptual test - adjust based on your asset handling
    skip "Asset requests are typically handled by web server, not Rails"
  end

  # =============================================================================
  # Throttle Response Headers
  # =============================================================================

  test "throttled response includes Retry-After header" do
    # Clear cache to ensure clean state
    Rack::Attack.cache.store.clear

    # Trigger login throttle
    6.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
    end

    retry_after = response.headers["Retry-After"]
    assert_not_nil retry_after, "Retry-After header should be present"
    assert retry_after.to_i > 0, "Retry-After should be a positive number"
  end

  test "throttled response returns 429 status code" do
    # Trigger throttle
    6.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
    end

    assert_equal 429, response.status, "Should return 429 Too Many Requests"
  end

  test "throttled response includes helpful error message" do
    # Trigger throttle
    6.times do
      post user_session_path, params: {
        user: { email: @user.email, password: "wrongpassword" }
      }
    end

    assert_match /too many requests/i, response.body.downcase,
      "Response should include informative error message"
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  test "blank email is not throttled" do
    # Requests without email should not trigger email-based throttles
    10.times do
      post user_session_path, params: {
        user: { email: "", password: "password" }
      }
    end

    # Should not be throttled (though login will fail for other reasons)
    assert_response :unprocessable_entity  # 422 - Invalid login, but not throttled
  end

  test "throttle cache clears between test runs" do
    # This test verifies our setup block is working correctly
    # First request should always succeed (no throttle from previous test)
    post user_session_path, params: {
      user: { email: @user.email, password: "wrongpassword" }
    }
    assert_response :unprocessable_entity, "First request after cache clear should not be throttled (422 for invalid login)"
  end
end
