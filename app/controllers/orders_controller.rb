class OrdersController < ApplicationController
  before_action :require_authentication!
  before_action :require_order_view_permission!, only: [:index]
  before_action :set_order, only: [:show]
  before_action :require_order_access!, only: [:show]
  before_action -> { require_permission!("orders.delete") }, only: [:destroy]

  def index
    @orders = authorized_order_scope(
      Order.includes(:user, :event, :payment, order_items: :pos_product)
           .order(created_at: :desc)
    )

    # By default, only show completed orders (with payments)
    unless params[:show_pending]
      @orders = @orders.joins(:payment).where(payments: { status: Payment::SUCCESS_STATUSES })
    end

    @show_pending = params[:show_pending].present?
  end

  def show
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Order ##{@order.id} was successfully deleted."
  end

  private

  def set_order
    @order = Order.includes(:user, :event, :payment, order_items: :pos_product)
                  .find(params[:id])
  end

  def require_order_view_permission!
    require_permission!("orders.view_all", "orders.view_event", "orders.view_own")
  end

  def require_order_access!
    return true if current_user_can_view_order?(@order)

    redirect_to orders_path, alert: "Not authorized"
    false
  end

  def authorized_order_scope(scope)
    return scope if current_user_can?("orders.view_all")

    conditions = []
    binds = {}

    if current_user_can?("orders.view_own")
      conditions << "orders.user_id = :user_id"
      binds[:user_id] = current_user.id
    end

    if current_user_can?("orders.view_event") && session[:current_event_id].present?
      conditions << "orders.event_id = :event_id"
      binds[:event_id] = session[:current_event_id]
    end

    return scope.none if conditions.empty?

    scope.where(conditions.join(" OR "), binds)
  end
end
