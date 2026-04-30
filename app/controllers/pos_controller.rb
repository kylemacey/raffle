class PosController < ApplicationController
  include PosHelper
  include ReadersHelper

  before_action :require_authentication!
  before_action -> { require_permission!("pos.sell") }, except: [:search_customers]
  before_action -> { require_permission!("customers.search") }, only: [:search_customers]
  before_action :load_cart_from_params, only: [:checkout]
  before_action :set_pos_order, only: [:success, :failure]
  before_action :require_pos_order_access!, only: [:success, :failure]
  before_action :use_full_width_container

  def new
    @events = Event.all
  end

  def create
    session[:current_event_id] = params[:event_id]
    redirect_to pos_main_path
  end

  def main
    @products = PosProduct.where(active: true).order(:priority)
    @event = current_event
  end

  def checkout
    if @cart_items.empty?
      redirect_to pos_main_path, alert: 'Your cart is empty.'
      return
    end

    if params[:payment_method] == 'card' && current_reader.blank?
      redirect_to readers_list_path, alert: 'Select a card reader before checking out with card.'
      return
    end

    order = nil
    begin
      ActiveRecord::Base.transaction do
        order = current_event.orders.create!(
          customer_name: params[:name],
          customer_email: params[:email],
          total_amount: @cart_total,
          user: current_user,
          payment_method_type: params[:payment_method]
        )

        @cart_items.each do |item|
          order.order_items.create!(
            pos_product: item[:product],
            quantity: item[:quantity],
            unit_price: item[:product].price
          )
        end

        if params[:payment_method] == 'cash'
          order.create_payment!(
            payment_method_type: 'cash',
            amount: @cart_total
          )
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to pos_main_path, alert: "Error creating order: #{e.message}"
      return
    end

    if params[:payment_method] == 'cash'
      # Use the new OrderProcessingService for cash payments
      result = OrderProcessingService.process_order(order)

      if result[:success]
        Rails.logger.info "Cash payment: Successfully processed Order ##{order.id} with #{result[:processed].count} items"
      else
        Rails.logger.error "Cash payment: Order ##{order.id} processing completed with #{result[:failed].count} failures"
        result[:failed].each do |failure|
          Rails.logger.error "  - Item #{failure[:item].id} (#{failure[:item].pos_product.name}): #{failure[:error].message}"
        end
      end

      redirect_to pos_success_path(order_id: order.id, cart_cleared: true)

    elsif params[:payment_method] == 'card'
      payment_service = CollectPaymentService.new(
        order: order,
        reader: current_reader
      )

      payment_service.collect_payment

      if payment_service.success?
        Rails.logger.info "Created #{payment_service.intent_type} for Order ##{order.id}"
        redirect_to(
          controller: :pos,
          action: :wait_for_pin_pad,
          intent_id: payment_service.intent_id
        )
      else
        order.destroy
        redirect_to pos_main_path, alert: 'Could not initiate card payment.'
      end
    end
  end

  def wait_for_pin_pad
    @terminal_intent = retrieve_terminal_intent(terminal_intent_id_param)
    @payment_intent = @terminal_intent if payment_intent_id?(terminal_intent_id_param)
    @setup_intent = @terminal_intent if setup_intent_id?(terminal_intent_id_param)

    respond_to do |format|
      format.html # Render the initial HTML view
      format.turbo_stream # Respond with a Turbo Stream if requested
    end
  end

  def create_order

  end

  def success
  end

  def failure
    if @order.payment&.stripe_intent_id.present?
      @terminal_intent = retrieve_terminal_intent(@order.payment.stripe_intent_id)
      @payment_intent = @terminal_intent if payment_intent_id?(@order.payment.stripe_intent_id)
      @setup_intent = @terminal_intent if setup_intent_id?(@order.payment.stripe_intent_id)
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Error retrieving payment intent: #{e.message}"
    redirect_to pos_main_path, alert: 'Payment information not found.'
  end

  # Turbo Action
  def custom_price
    tickets = params[:tickets].to_i
    price = RaffleProduct.custom_price(tickets)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("custom_price", partial: "pos/custom_price", locals: { price: price })
      end
    end
  end

  def simulate_payment
    if Rails.env.development? && current_reader&.device_type&.start_with?('simulated')
      begin
        Stripe::Terminal::Reader::TestHelpers.present_payment_method(current_reader.id)
      rescue Stripe::StripeError => e
        flash[:alert] = "Error simulating payment: #{e.message}"
        redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) and return
      end
    else
      flash[:alert] = "Payment simulation is only available for simulated readers in development."
      redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) and return
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("simulation_controls", partial: "pos/simulation_status", locals: { message: "Success simulation sent." }) }
      format.html { redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) }
    end
  end

  def simulate_decline
    if Rails.env.development? && current_reader&.device_type&.start_with?('simulated')
      begin
        Stripe::Terminal::Reader::TestHelpers.present_payment_method(
          current_reader.id,
          {
            card_present: { number: '4000000000000002'},
            type: "card_present",
          }
        )
      rescue Stripe::StripeError => e
        flash[:alert] = "Error simulating decline: #{e.message}"
        redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) and return
      end
    else
      flash[:alert] = "Payment simulation is only available for simulated readers in development."
      redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) and return
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("simulation_controls", partial: "pos/simulation_status", locals: { message: "Decline simulation sent." }) }
      format.html { redirect_to pos_wait_for_pin_pad_path(intent_id: terminal_intent_id_param) }
    end
  end

  def search_customers
    query = params[:query]
    if query.blank?
      render json: []
      return
    end

    begin
      customers = Stripe::Customer.search(
        query: %{name~"#{query}" OR email~"#{query}"},
        limit: 10
      )
      render json: customers.data.map { |c| { id: c.id, name: c.name, email: c.email } }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe customer search error: #{e.message}"
      render json: { error: "Failed to search customers" }, status: :internal_server_error
    end
  end

  private

  def set_pos_order
    @order = Order.find(params[:order_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to pos_main_path, alert: 'Order not found.'
    false
  end

  def require_pos_order_access!
    return true if @order && current_user_can_view_order?(@order)

    redirect_to pos_main_path, alert: 'Not authorized'
    false
  end

  def terminal_intent_id_param
    params[:intent_id] || params[:payment_intent_id] || params[:setup_intent_id]
  end

  def retrieve_terminal_intent(intent_id)
    if setup_intent_id?(intent_id)
      Stripe::SetupIntent.retrieve(intent_id)
    else
      Stripe::PaymentIntent.retrieve(intent_id)
    end
  end

  def setup_intent_id?(intent_id)
    intent_id.to_s.start_with?("seti_")
  end

  def payment_intent_id?(intent_id)
    !setup_intent_id?(intent_id)
  end

  def load_cart_from_params
    cart_data = params[:cart_data]
    unless cart_data
      @cart_items = []
      @cart_total = 0
      return
    end

    begin
      cart = JSON.parse(cart_data)
      product_ids = cart.keys
      @cart_products = PosProduct.where(id: product_ids)

      @cart_items = @cart_products.map do |product|
        {
          product: product,
          quantity: cart[product.id.to_s] || 0
        }
      end.compact

      @cart_total = @cart_items.sum { |item| item[:product].price * item[:quantity] }
    rescue JSON::ParserError
      redirect_to pos_main_path, alert: 'Invalid cart data.'
    end
  end
end
