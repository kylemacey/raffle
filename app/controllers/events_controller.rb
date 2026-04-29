class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy ]
  before_action -> { require_permission!("events.view") }, only: %i[ index show ]
  before_action -> { require_permission!("events.manage") }, except: %i[ index show ]

  # GET /events or /events.json
  def index
    @events = Event.all
  end

  # GET /events/1 or /events/1.json
  def show
    @show_event_financials = current_user_can?("reports.view_fundraising")
    @show_supporter_details = current_user_can?("reports.view_pii")

    if @show_event_financials
      @stats = {
        total_entries: @event.entries.sum(:qty),
        total_orders: @event.orders.joins(:payment).count,
        gross_volume: @event.orders.joins(:payment).sum(:total_amount)
      }
    end

    if @show_supporter_details && @stats && @stats[:total_entries] > 0
      @heavy_hitters = @event.entries
                             .group(:name)
                             .order('sum_qty desc')
                             .sum(:qty)
                             .first(5)
                             .map do |name, qty|
                               {
                                 name: name,
                                 qty: qty,
                                 percentage: (qty.to_f / @stats[:total_entries] * 100).round(2)
                               }
                             end
    else
      @heavy_hitters = []
    end

    @drawings = @event.drawings.includes(:winners).order(created_at: :desc)
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to event_url(@event), notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to event_url(@event), notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:name)
    end
end
