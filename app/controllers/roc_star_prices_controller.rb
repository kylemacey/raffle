class RocStarPricesController < ApplicationController
  before_action :set_roc_star_price, only: %i[ show edit update destroy ]

  # GET /roc_star_prices or /roc_star_prices.json
  def index
    @roc_star_prices = RocStarPrice.all
  end

  # GET /roc_star_prices/1 or /roc_star_prices/1.json
  def show
  end

  # GET /roc_star_prices/new
  def new
    @roc_star_price = RocStarPrice.new
  end

  # GET /roc_star_prices/1/edit
  def edit
  end

  # POST /roc_star_prices or /roc_star_prices.json
  def create
    @roc_star_price = RocStarPrice.new(roc_star_price_params)

    respond_to do |format|
      if @roc_star_price.save
        format.html { redirect_to roc_star_price_url(@roc_star_price), notice: "Roc star price was successfully created." }
        format.json { render :show, status: :created, location: @roc_star_price }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @roc_star_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /roc_star_prices/1 or /roc_star_prices/1.json
  def update
    respond_to do |format|
      if @roc_star_price.update(roc_star_price_params)
        format.html { redirect_to roc_star_price_url(@roc_star_price), notice: "Roc star price was successfully updated." }
        format.json { render :show, status: :ok, location: @roc_star_price }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @roc_star_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roc_star_prices/1 or /roc_star_prices/1.json
  def destroy
    @roc_star_price.destroy

    respond_to do |format|
      format.html { redirect_to roc_star_prices_url, notice: "Roc star price was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_roc_star_price
      @roc_star_price = RocStarPrice.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def roc_star_price_params
      params.require(:roc_star_price).permit(:name, :product_id, :amount, :interval, :description)
    end
end
