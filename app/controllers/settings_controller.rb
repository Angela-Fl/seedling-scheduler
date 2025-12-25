class SettingsController < ApplicationController
  def edit
    @frost_date = Setting.frost_date
  end

  def update
    new_date = Date.parse(params[:frost_date])

    Setting.set_frost_date(new_date)

    # SECURITY FIX: Only regenerate tasks for current user's plants
    current_user.plants.find_each do |plant|
      plant.generate_tasks!(Setting.frost_date)
    end

    redirect_to edit_settings_path, notice: "Frost date updated and tasks regenerated."
  rescue ArgumentError
    flash.now[:alert] = "Invalid date format"
    @frost_date = Setting.frost_date
    render :edit, status: :unprocessable_entity
  end
end
