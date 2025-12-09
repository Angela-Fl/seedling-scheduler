class TasksController < ApplicationController
  def index
    @tasks = Task
      .includes(:plant)
      .where("due_date >= ?", Date.current - Task::HISTORY_DAYS.days)
      .order(:due_date)
  end
end
