# frozen_string_literal: true

# Rack::Attack is a rack middleware to protect your web app from bad clients.
# It allows custom throttling and blocking of requests.

class Rack::Attack
  ### Configure Cache ###

  # Use Rails cache store for Rack::Attack's throttle data
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Login Attempts by Email ###

  # Limit login attempts to 5 requests per 20 seconds per email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize the email to prevent case variations from bypassing throttle
      ActionDispatch::Request.new(req.env).params.dig("user", "email")&.to_s&.downcase&.presence
    end
  end

  ### Throttle Password Reset Requests by Email ###

  # Limit password reset requests to 3 per 5 minutes per email
  throttle("password_resets/email", limit: 3, period: 5.minutes) do |req|
    if req.path == "/users/password" && req.post?
      ActionDispatch::Request.new(req.env).params.dig("user", "email")&.to_s&.downcase&.presence
    end
  end

  ### Throttle Registration Attempts by IP ###

  # Limit registration attempts to 5 per hour per IP
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  ### Throttle Account Unlock Requests ###

  # Limit unlock requests to 3 per 5 minutes per email
  throttle("unlocks/email", limit: 3, period: 5.minutes) do |req|
    if req.path == "/users/unlock" && req.post?
      ActionDispatch::Request.new(req.env).params.dig("user", "email")&.to_s&.downcase&.presence
    end
  end

  ### Throttle Confirmation Resend Requests ###

  # Limit confirmation email resends to 3 per 5 minutes per email
  throttle("confirmations/email", limit: 3, period: 5.minutes) do |req|
    if req.path == "/users/confirmation" && req.post?
      ActionDispatch::Request.new(req.env).params.dig("user", "email")&.to_s&.downcase&.presence
    end
  end

  ### General Request Rate Limiting by IP ###

  # Allow higher general request rate (100 requests per minute)
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Custom Response for Throttled Requests ###

  # Return 429 (Too Many Requests) when throttle limit is exceeded
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    retry_after = match_data[:period] || 60
    [
      429,
      {
        "Content-Type" => "text/html",
        "Retry-After" => retry_after.to_s
      },
      [ "<html><body><h1>Too Many Requests</h1><p>Please try again later.</p></body></html>" ]
    ]
  end

  ### Logging (Optional) ###

  # Log blocked requests in production
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack][Throttled] #{req.env["rack.attack.matched"]} - IP: #{req.ip} - Path: #{req.path}"
  end
end
