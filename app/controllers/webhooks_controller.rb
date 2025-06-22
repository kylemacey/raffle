class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    # Verify the webhook signature
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_ENDPOINT_SECRET']
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook error: #{e.message}"
      render json: { error: e.message }, status: :bad_request and return
    end

    # Handle the event
    case event['type']
    when 'terminal.reader.action_succeeded'
      reader = event['data']['object']
      payment_intent = Stripe::PaymentIntent.retrieve(reader["action"]["process_payment_intent"]["payment_intent"])
      handle_payment_success(payment_intent)
    when 'terminal.reader.action_failed'
      reader = event['data']['object']
      payment_intent = Stripe::PaymentIntent.retrieve(reader["action"]["process_payment_intent"]["payment_intent"])
      handle_payment_failure(payment_intent)
    else
      Rails.logger.info "Unhandled event type: #{event['type']}"
    end

    render json: { status: "received" }, status: :ok
  end

  private

  def handle_payment_success(payment_intent)
    payment_intent_id = payment_intent.id
    metadata = payment_intent.metadata
    order_id = metadata['order_id']

    # Log an error and return if the order_id is missing from the metadata
    unless order_id
      Rails.logger.error "Webhook Error: No order_id present in metadata for PaymentIntent #{payment_intent_id}"
      return
    end

    # Log an error and return if the order can't be found
    unless Order.exists?(order_id)
      Rails.logger.error "Webhook Error: Could not find Order with ID #{order_id} for PaymentIntent #{payment_intent_id}"
      return
    end

    Rails.logger.info "Webhook: Payment succeeded for Order ##{order_id}, preparing to broadcast and process."

    # Broadcast redirect to success page
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{payment_intent_id}",
      target: "redirect_target",
      partial: "pos/redirect",
      locals: { url: pos_success_path(order_id: order_id) }
    )

    # Process the order in a background thread to avoid webhook timeouts
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        order = Order.find(order_id) # Find the order again within the thread

        # Use a lock to prevent race conditions on the payment record
        order.with_lock do
          if order.payment.nil?
            Stripe::PaymentIntent.capture(payment_intent_id)
            order.create_payment!(
              payment_method_type: 'card',
              amount: payment_intent.amount,
              payment_intent_id: payment_intent_id
            )

            # Use the new OrderProcessingService
            result = OrderProcessingService.process_order(order)

            if result[:success]
              Rails.logger.info "Webhook (Thread): Successfully processed Order ##{order_id} with #{result[:processed].count} items"
            else
              Rails.logger.error "Webhook (Thread): Order ##{order_id} processing completed with #{result[:failed].count} failures"
              result[:failed].each do |failure|
                Rails.logger.error "  - Item #{failure[:item].id} (#{failure[:item].pos_product.name}): #{failure[:error].message}"
              end
            end
          else
            Rails.logger.warn "Webhook (Thread): Order ##{order_id} already has a payment. Skipping."
          end
        end
      end
    end
  end

  def handle_payment_failure(payment_intent)
    # Extract the Payment Intent ID
    payment_intent_id = payment_intent.id
    metadata = payment_intent.metadata
    order_id = metadata['order_id']

    Rails.logger.info "Payment failed for #{payment_intent_id}"

    # Broadcast redirect to failure page
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{payment_intent_id}",
      target: "redirect_target",
      partial: "pos/redirect",
      locals: { url: pos_failure_path(order_id: order_id) }
    )
  end
end
