class PosController < ApplicationController
  include PosHelper
  include ReadersHelper

  before_action :require_authentication!
  before_action :load_cart_from_params, only: [:checkout]

  def new
    @events = Event.all
  end

  def create
    session[:current_event_id] = params[:event_id]
    redirect_to pos_main_path
  end

  def main
    redirect_to pos_path unless current_event
    @products = PosProduct.active
  end

  def checkout
    if @cart_items.empty?
      redirect_to pos_main_path, alert: 'Your cart is empty.'
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
        customer: { name: params[:name], email: params[:email] },
        reader: current_reader
      )

      payment_service.collect_payment(
        @cart_total,
        metadata: {
          order_id: order.id,
          event_id: current_event.id,
          agent: current_user.name,
          order_url: order_url(order.id)
        }
      )

      if payment_service.success?
        Rails.logger.info "Created payment intent for Order ##{order.id} with order URL: #{order_url(order.id)}"
        redirect_to(
          controller: :pos,
          action: :wait_for_pin_pad,
          payment_intent_id: payment_service.payment_intent.id
        )
      else
        order.destroy
        redirect_to pos_main_path, alert: 'Could not initiate card payment.'
      end
    end
  end

  def wait_for_pin_pad
    @payment_intent = Stripe::PaymentIntent.retrieve(params[:payment_intent_id])

    respond_to do |format|
      format.html # Render the initial HTML view
      format.turbo_stream # Respond with a Turbo Stream if requested
    end
  end

  def create_order

  end

  def success
    @order = Order.find(params[:order_id])
  end

  def failure
    @order = Order.find(params[:order_id])
    @payment_intent = Stripe::PaymentIntent.retrieve(@order.payment.payment_intent_id) if @order.payment&.payment_intent_id
  rescue ActiveRecord::RecordNotFound
    redirect_to pos_main_path, alert: 'Order not found.'
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
        redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) and return
      end
    else
      flash[:alert] = "Payment simulation is only available for simulated readers in development."
      redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) and return
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("simulation_controls", partial: "pos/simulation_status", locals: { message: "Success simulation sent." }) }
      format.html { redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) }
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
        redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) and return
      end
    else
      flash[:alert] = "Payment simulation is only available for simulated readers in development."
      redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) and return
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("simulation_controls", partial: "pos/simulation_status", locals: { message: "Decline simulation sent." }) }
      format.html { redirect_to pos_wait_for_pin_pad_path(payment_intent_id: params[:payment_intent_id]) }
    end
  end

  private

  def load_cart_from_params
    cart_data = params[:cart_data]
    return unless cart_data

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
