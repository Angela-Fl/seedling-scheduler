class PlantsController < ApplicationController
  before_action :set_plant, only: [:show, :edit, :update, :destroy, :regenerate_tasks]

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
    params.require(:plant).permit(
      :name,
      :variety,
      :sowing_method,
      :weeks_before_last_frost_to_start,
      :weeks_before_last_frost_to_transplant,
      :weeks_after_last_frost_to_direct_sow,
      :notes
    )
  end
end
