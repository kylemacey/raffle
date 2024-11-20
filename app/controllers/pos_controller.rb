class PosController < ApplicationController
  def main
    @products = RaffleProduct.all
  end

  def checkout
  end

  def create_order
  end

  def success
  end
end
