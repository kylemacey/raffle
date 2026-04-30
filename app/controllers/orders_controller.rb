class OrdersController < ApplicationController
  before_action :require_authentication!
  before_action :set_order, only: [:show]

  def index
    @orders = Order.includes(:user, :event, :payment, order_items: :pos_product)
                   .order(created_at: :desc)

    # By default, only show completed orders (with payments)
    unless params[:show_pending]
      @orders = @orders.joins(:payment).where(payments: { status: Payment::SUCCESS_STATUSES })
    end

    @show_pending = params[:show_pending].present?
  end

  def show
  end

  def destroy
    unless current_user_is_admin?
      redirect_to orders_path, alert: "You are not authorized to perform this action."
      return
    end

    @order = Order.find(params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Order ##{@order.id} was successfully deleted."
  end

  private

  def set_order
    @order = Order.includes(:user, :event, :payment, order_items: :pos_product)
                  .find(params[:id])
  end
end
