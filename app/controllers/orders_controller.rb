class OrdersController < ApplicationController
  before_action :require_admin!
  before_action :set_order, only: [:show]

  def index
    @orders = Order.includes(:user, :event, :payment, order_items: :pos_product)
                   .order(created_at: :desc)
  end

  def show
  end

  private

  def set_order
    @order = Order.includes(:user, :event, :payment, order_items: :pos_product)
                  .find(params[:id])
  end
end
