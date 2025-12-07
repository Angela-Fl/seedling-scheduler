class TasksController < ApplicationController
  def index
    @tasks = Task
      .includes(:plant)
      .where("due_date >= ?", Date.today - 7)   # show a bit of history
      .order(:due_date)
  end
end

