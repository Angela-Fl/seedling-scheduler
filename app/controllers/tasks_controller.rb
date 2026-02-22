class TasksController < ApplicationController
  before_action :set_task, only: [ :update, :complete, :skip, :reset, :destroy ]

  def index
    base_query = current_user.tasks
      .includes(:plant)
      .left_joins(:plant)
      .where("plants.muted_at IS NULL OR tasks.plant_id IS NULL")
      .order(:due_date)

    respond_to do |format|
      format.html do
        @tasks = base_query
      end
      format.json do
        tasks = if params[:start] && params[:end]
          start_date = Date.parse(params[:start])
          end_date = Date.parse(params[:end])
          base_query.where(due_date: start_date..end_date)
        else
          base_query.where("due_date >= ?", Date.current - Task::HISTORY_DAYS.days)
        end

        render json: tasks.map { |t| task_to_json(t) }
      end
    end
  end

  def create
    @task = current_user.tasks.new(task_params)

    # If a plant_id is supplied, ensure it belongs to the current user.
    if @task.plant_id.present?
      plant = current_user.plants.find_by(id: @task.plant_id)
      return render json: { error: "Plant not found" }, status: :not_found unless plant

      @task.plant = plant
      @task.user = current_user
    end

    if @task.save
      render json: task_to_json(@task), status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def update
    # If the update includes plant_id, ensure you can only set it to one of your plants.
    if task_params.key?(:plant_id)
      if task_params[:plant_id].present?
        plant = current_user.plants.find_by(id: task_params[:plant_id])
        return render json: { error: "Plant not found" }, status: :not_found unless plant
      end
      # If plant_id is blank, that means "general task" — allowed.
    end

    if @task.update(task_params)
      render json: task_to_json(@task)
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def calendar
    # Calendar view
  end

  def complete
    @task.done!
    render json: task_to_json(@task)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def skip
    @task.skip!
    render json: task_to_json(@task)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def reset
    @task.update!(status: "pending")
    render json: task_to_json(@task)
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @task.destroy!
    head :no_content
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    # NOTE: We intentionally do NOT permit :user_id. Ownership is server-controlled.
    params.require(:task).permit(:due_date, :task_type, :status, :notes, :plant_id)
  end

  def task_to_json(task)
    {
      id: task.id,
      due_date: task.due_date.iso8601,
      end_date: task.end_date&.iso8601,
      task_type: task.task_type,
      status: task.status,
      notes: task.notes,
      plant_id: task.plant_id,
      plant_name: task.plant&.name,
      plant_variety: task.plant&.variety
    }
  end
end
