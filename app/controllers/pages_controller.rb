class PagesController < ApplicationController
  # Allow public access to getting started page
  skip_before_action :authenticate_user!, only: [ :getting_started ]

  def getting_started
    # Public page - no authentication required
  end
end
