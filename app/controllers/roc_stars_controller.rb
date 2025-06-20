class RocStarsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :http_basic_authenticate_with, raise: false
  before_action :set_all_prices

  def prices
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

  def new_session
    response.headers.delete "X-Frame-Options"
    render layout: 'iframe'
  end

  def success
    # Renders app/views/roc_stars/success.html.erb
    redirect_to "https://farleysfriends.org/roc-star-success"
  end

  def cancel
    # Renders app/views/roc_stars/cancel.html.erb
    redirect_to "https://farleysfriends.org/roc-stars"
  end

  private

  def set_all_prices
    @prices = RocStarPrice.all
  end

  def checkout_params
    params.require(:roc_star).permit(:amount, :email, :name, :interval_type)
  end
end
