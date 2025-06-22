class OrdersController < ApplicationController
  before_action :require_admin!
  before_action :set_order, only: [:show]

  def index
    @orders = Order.includes(:user, :event, :payment, order_items: :pos_product)
                   .order(created_at: :desc)

    # By default, only show completed orders (with payments)
    unless params[:show_pending]
      @orders = @orders.joins(:payment)
    end

    @show_pending = params[:show_pending].present?
  end

  def show
  end

  private

  def set_order
    @order = Order.includes(:user, :event, :payment, order_items: :pos_product)
                  .find(params[:id])
  end
end
