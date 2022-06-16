class DrawingsController < ApplicationController
  before_action :set_event
  before_action :set_drawing, only: %i[ show edit update destroy winners ]

  # GET /drawings or /drawings.json
  def index
    @drawings = @event.drawings
  end

  # GET /drawings/1 or /drawings/1.json
  def show
  end

  # GET /drawings/new
  def new
    @drawing = @event.drawings.new
  end

  # GET /drawings/1/edit
  def edit
  end

  # POST /drawings or /drawings.json
  def create
    @drawing = @event.drawings.new(drawing_params)
    drawing_service = DrawingService.new(@drawing)

    respond_to do |format|
      if drawing_service.perform_drawing
        format.html { redirect_to event_drawing_winners_url(@event, @drawing), notice: "Drawing was successfully created." }
        format.json { render :show, status: :created, location: @drawing }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @drawing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /drawings/1 or /drawings/1.json
  def update
    respond_to do |format|
      if @drawing.update(drawing_params)
        format.html { redirect_to drawing_url(@drawing), notice: "Drawing was successfully updated." }
        format.json { render :show, status: :ok, location: @drawing }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @drawing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /drawings/1 or /drawings/1.json
  def destroy
    @drawing.destroy

    respond_to do |format|
      format.html { redirect_to drawings_url, notice: "Drawing was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def winners
    respond_to do |format|
      format.html
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=#{@event.name} Drawing #{@drawing.id} winners.csv"

        doc = CSV.generate do |csv|
          csv << ["Name", "Contact"]
          @drawing.winners.includes(:entry).each do |winner|
            csv << [
              winner.entry.name,
              winner.entry.phone,
            ]
          end
        end

        render plain: doc
      end
    end
  end

  private
    def set_event
      @event = Event.find(params[:event_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_drawing
      @drawing = @event.drawings.find(params[:id] || params[:drawing_id])
    end

    # Only allow a list of trusted parameters through.
    def drawing_params
      params.require(:drawing).permit(:qty, :can_win_again)
    end
end
