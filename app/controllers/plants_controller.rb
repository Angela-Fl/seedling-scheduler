class PlantsController < ApplicationController
  before_action :set_plant, only: [ :show, :edit, :update, :destroy, :regenerate_tasks ]

  def index
    @plants = Plant.order(:name)
  end

  def show
    @tasks = @plant.tasks.order(:due_date)
  end

  def new
    @plant = Plant.new
  end

  def edit
  end

  def create
    @plant = Plant.new(plant_params)

    if @plant.save
      @plant.generate_tasks!(Setting.frost_date)
      redirect_to @plant, notice: "Plant was created and tasks generated."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @plant.update(plant_params)
      @plant.generate_tasks!(Setting.frost_date)
      redirect_to @plant, notice: "Plant was updated and tasks regenerated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @plant.destroy
    redirect_to plants_path, notice: "Plant deleted."
  end

  def regenerate_tasks
    @plant.generate_tasks!(Setting.frost_date)
    redirect_to @plant, notice: "Tasks regenerated based on current settings."
  end

  private

  def set_plant
    @plant = Plant.find(params[:id])
  end

  def plant_params
    # Start with basic permitted params
    permitted = params.require(:plant).permit(
      :name, :variety, :sowing_method, :notes,
      :plant_seeds_weeks, :plant_seeds_unit, :plant_seeds_direction,
      :hardening_weeks, :hardening_unit, :hardening_direction,
      :plant_seedlings_weeks, :plant_seedlings_unit, :plant_seedlings_direction
    )

    # Convert user-friendly inputs to offset_days
    convert_offset_param(permitted, :plant_seeds)
    convert_offset_param(permitted, :hardening)
    convert_offset_param(permitted, :plant_seedlings)

    # Return only the offset fields (remove temporary UI fields)
    permitted.except(
      :plant_seeds_weeks, :plant_seeds_unit, :plant_seeds_direction,
      :hardening_weeks, :hardening_unit, :hardening_direction,
      :plant_seedlings_weeks, :plant_seedlings_unit, :plant_seedlings_direction
    )
  end

  def convert_offset_param(params, prefix)
    weeks_key = "#{prefix}_weeks"
    unit_key = "#{prefix}_unit"
    direction_key = "#{prefix}_direction"
    offset_key = "#{prefix}_offset_days"

    weeks = params[weeks_key]
    unit = params[unit_key]
    direction = params[direction_key]

    return unless weeks.present?

    # Convert to days
    days = unit == "weeks" ? weeks.to_i * 7 : weeks.to_i

    # Apply direction (before = negative, after = positive)
    days *= -1 if direction == "before"

    params[offset_key] = days
  end
end
