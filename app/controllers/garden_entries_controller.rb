class GardenEntriesController < ApplicationController
  before_action :set_garden_entry, only: %i[ show edit update destroy ]

  # GET /garden_entries or /garden_entries.json
  def index
    @garden_entries = GardenEntry.order(entry_date: :desc, created_at: :desc)
  end

  # GET /garden_entries/1 or /garden_entries/1.json
  def show
  end

  # GET /garden_entries/new
  def new
    @garden_entry = GardenEntry.new
  end

  # GET /garden_entries/1/edit
  def edit
  end

  # POST /garden_entries or /garden_entries.json
  def create
    @garden_entry = GardenEntry.new(garden_entry_params)

    respond_to do |format|
      if @garden_entry.save
        format.html { redirect_to garden_entries_path, notice: "Garden entry was successfully created." }
        format.json { render :show, status: :created, location: @garden_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @garden_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /garden_entries/1 or /garden_entries/1.json
  def update
    respond_to do |format|
      if @garden_entry.update(garden_entry_params)
        format.html { redirect_to garden_entries_path, notice: "Garden entry was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @garden_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @garden_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /garden_entries/1 or /garden_entries/1.json
  def destroy
    @garden_entry.destroy!

    respond_to do |format|
      format.html { redirect_to garden_entries_path, notice: "Garden entry was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_garden_entry
      @garden_entry = GardenEntry.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def garden_entry_params
      params.expect(garden_entry: [ :entry_date, :body ])
    end
end
