class RocStarsController < ApplicationController
  def prices
    @prices = RocStarPrice.all


    respond_to do |format|
      format.json { @prices.to_json }
    end
  end

  def create_checkout_session

  end
end
