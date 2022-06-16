require 'csv'

class EntriesController < ApplicationController
  before_action :set_event
  before_action :set_entry, only: %i[ show edit update destroy ]

  # GET /entries or /entries.json
  def index
    @entries = @event.entries.all
  end

  # GET /entries/1 or /entries/1.json
  def show
  end

  # GET /entries/new
  def new
    @entry = Entry.new
  end

  # GET /entries/1/edit
  def edit
  end

  # POST /entries or /entries.json
  def create
    @entry = @event.entries.new(entry_params)

    respond_to do |format|
      if @entry.save
        format.html { redirect_to new_event_entry_url(@event), notice: "Entry created for #{@entry.name}." }
        format.json { render :show, status: :created, location: @entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /entries/1 or /entries/1.json
  def update
    respond_to do |format|
      if @entry.update(entry_params)
        format.html { redirect_to event_entries_url(@event), notice: "Entry was successfully updated." }
        format.json { render :show, status: :ok, location: @entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /entries/1 or /entries/1.json
  def destroy
    @entry.destroy

    respond_to do |format|
      format.html { redirect_to event_entries_url(@event), notice: "Entry was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
    file = params[:csv_upload]

    CSV.foreach(file, headers: true) do |row|
      qty = row["Lineitem quantity"].to_i
      variant = [row["Lineitem variant"][/(\d+) tickets/, 1].to_i, 1].max
      total_qty = qty * variant

      @event.entries.create(
        name: row["Billing Name"],
        phone: row["Email"] + " " + row["Billing Phone"],
        qty: total_qty
      )
    end

    redirect_to event_entries_url(@event), notice: "Entries were successfully imported."
  end

  private
    def set_event
      @event = Event.find(params[:event_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def entry_params
      params.require(:entry).permit(:name, :phone, :qty, :event_id)
    end
end
