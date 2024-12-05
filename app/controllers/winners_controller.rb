class WinnersController < ApplicationController
  before_action :set_event
  before_action :set_drawing
  before_action :set_winner, only: %i[ show edit update destroy ]

  # GET /winners or /winners.json
  def index
    @winners = @drawing.winners

    respond_to do |format|
      format.html
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=#{@event.name} Drawing #{@drawing.id} winners.csv"

        doc = CSV.generate do |csv|
          csv << ["Name", "Contact", "Prize Number", "Claimed"]
          @winners.includes(:entry).each do |winner|
            csv << [
              winner.entry.name,
              winner.entry.phone,
              winner.prize_number,
              winner.claimed?
            ]
          end
        end

        render plain: doc
      end
    end
  end

  # GET /winners/1 or /winners/1.json
  def show
  end

  # GET /winners/by_prize_number?prize_number=
  def by_prize_number
    if @winner = @drawing.winners.find_by(prize_number: params[:prize_number])
      redirect_to [@event, @drawing, @winner]
    else
      redirect_to [@event, @drawing, :winners], notice: "Prize not found: #{params[:prize_number]}"
    end
  end

  # GET /winners/new
  def new
    @winner = Winner.new
  end

  # GET /winners/1/edit
  def edit
  end

  # POST /winners or /winners.json
  def create
    @winner = Winner.new(winner_params)

    respond_to do |format|
      if @winner.save
        format.html { redirect_to winner_url(@winner), notice: "Winner was successfully created." }
        format.json { render :show, status: :created, location: @winner }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @winner.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /winners/1 or /winners/1.json
  def update
    respond_to do |format|
      if @winner.update(winner_params)
        format.html { redirect_to winner_url(@winner), notice: "Winner was successfully updated." }
        format.json { render :show, status: :ok, location: @winner }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @winner.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /winners/1 or /winners/1.json
  def destroy
    @winner.destroy

    respond_to do |format|
      format.html { redirect_to winners_url, notice: "Winner was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_winner
      @winner = @drawing.winners.find(params[:id])
    end

    def set_event
      @event = Event.find(params[:event_id])
    end

    def set_drawing
      @drawing = @event.drawings.find(params[:drawing_id])
    end

    # Only allow a list of trusted parameters through.
    def winner_params
      params.fetch(:winner, {}).permit([:claimed])
    end
end
