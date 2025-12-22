class TasksController < ApplicationController
  before_action :set_task, only: [ :update, :complete, :skip, :reset ]

  def index
    @tasks = Task
      .includes(:plant)
      .where("due_date >= ?", Date.current - Task::HISTORY_DAYS.days)
      .order(:due_date)

    respond_to do |format|
      format.html
      format.json do
        if params[:start] && params[:end]
          start_date = Date.parse(params[:start])
          end_date = Date.parse(params[:end])
          @tasks = @tasks.where(due_date: start_date..end_date)
        end
        render json: @tasks.map { |t| task_to_json(t) }
      end
    end
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      render json: task_to_json(@task), status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def update
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

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:due_date, :task_type, :status, :notes, :plant_id)
  end

  def task_to_json(task)
    {
      id: task.id,
      due_date: task.due_date.iso8601,
      task_type: task.task_type,
      status: task.status,
      notes: task.notes,
      plant_id: task.plant_id,
      plant_name: task.plant&.name,
      plant_variety: task.plant&.variety
    }
  end
end
