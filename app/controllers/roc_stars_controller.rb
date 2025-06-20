class RocStarsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_all_prices

  def prices
    @prices = RocStarPrice.all

    respond_to do |format|
      format.json { render json: @prices }
    end
  end

  def create_checkout_session
    service = CreateCheckoutSessionService.new(checkout_params, request: request)

    if service.create_checkout_session
      render json: service.response
    else
      render json: { error: service.error }, status: :unprocessable_entity
    end
  end

  private

  def set_all_prices
    @all_prices = RocStarPrice.all
  end

  def checkout_params
    params.require(:roc_star).permit(:amount, :email, :name, :interval_type)
  end
end
