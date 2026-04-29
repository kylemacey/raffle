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
      handle_terminal_action_succeeded(reader)
    when 'terminal.reader.action_failed'
      reader = event['data']['object']
      handle_terminal_action_failed(reader)
    else
      Rails.logger.info "Unhandled event type: #{event['type']}"
    end

    render json: { status: "received" }, status: :ok
  end

  private

  def handle_terminal_action_succeeded(reader)
    action = reader["action"]

    case action["type"]
    when "process_payment_intent"
      payment_intent_id = action["process_payment_intent"]["payment_intent"]
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      handle_payment_success(payment_intent)
    when "process_setup_intent"
      setup_intent_id = action["process_setup_intent"]["setup_intent"]
      setup_intent = retrieve_setup_intent(setup_intent_id, expand_latest_attempt: true)
      handle_setup_success(setup_intent)
    else
      Rails.logger.info "Unhandled terminal action type: #{action['type']}"
    end
  end

  def handle_terminal_action_failed(reader)
    action = reader["action"]

    case action["type"]
    when "process_payment_intent"
      payment_intent_id = action["process_payment_intent"]["payment_intent"]
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      handle_payment_failure(payment_intent)
    when "process_setup_intent"
      setup_intent_id = action["process_setup_intent"]["setup_intent"]
      setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)
      handle_setup_failure(setup_intent)
    else
      Rails.logger.info "Unhandled failed terminal action type: #{action['type']}"
    end
  end

  def handle_payment_success(payment_intent)
    payment_intent_id = payment_intent.id
    order_id = order_id_from_metadata(payment_intent)

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

    broadcast_success_redirect(payment_intent_id, order_id)

    # Process the order in a background thread to avoid webhook timeouts
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        process_payment_success(order_id, payment_intent)
      end
    end
  end

  def process_payment_success(order_id, payment_intent)
    payment_intent_id = payment_intent.id
    order = Order.find(order_id)

    order.with_lock do
      if order.payment&.succeeded?
        Rails.logger.warn "Webhook (Thread): Order ##{order_id} already has a successful payment. Skipping."
        next
      end

      Stripe::PaymentIntent.capture(payment_intent_id)
      payment = order.payment || order.build_payment
      payment.update!(
        payment_method_type: 'card',
        amount: payment_intent.amount,
        payment_intent_id: payment_intent_id,
        status: 'succeeded'
      )

      result = OrderProcessingService.process_order(order)
      log_order_processing_result(order, result)

      subscription = create_subscription_from_payment_intent(order, payment_intent)
      payment.update!(stripe_subscription_id: subscription.id) if subscription
    end
  end

  def handle_setup_success(setup_intent)
    setup_intent_id = setup_intent.id
    order_id = order_id_from_metadata(setup_intent)

    unless order_id
      Rails.logger.error "Webhook Error: No order_id present in metadata for SetupIntent #{setup_intent_id}"
      return
    end

    unless Order.exists?(order_id)
      Rails.logger.error "Webhook Error: Could not find Order with ID #{order_id} for SetupIntent #{setup_intent_id}"
      return
    end

    Rails.logger.info "Webhook: Setup succeeded for Order ##{order_id}, preparing to process subscription."

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        process_setup_success(order_id, setup_intent)
      end
    end
  end

  def process_setup_success(order_id, setup_intent)
    setup_intent_id = setup_intent.id
    order = Order.find(order_id)

    order.with_lock do
      if order.payment&.succeeded?
        Rails.logger.warn "Webhook (Thread): Order ##{order_id} already has a successful setup. Skipping."
        next
      end

      payment = order.payment || order.build_payment
      payment.update!(
        payment_method_type: 'card',
        amount: 0,
        stripe_setup_intent_id: setup_intent_id,
        status: 'processing'
      )

      generated_card_pm_id = generated_card_from_setup_intent(setup_intent)
      unless generated_card_pm_id
        Rails.logger.error "Webhook (Thread): Could not find a generated card for SetupIntent #{setup_intent_id}."
        payment.update!(status: 'failed')
        broadcast_failure_redirect(setup_intent_id, order.id)
        next
      end

      subscription = create_subscription_for_order(order, setup_intent.customer, generated_card_pm_id)
      unless subscription
        payment.update!(status: 'failed')
        broadcast_failure_redirect(setup_intent_id, order.id)
        next
      end

      result = OrderProcessingService.process_order(order)
      log_order_processing_result(order, result)

      payment.update!(
        status: 'succeeded',
        stripe_subscription_id: subscription.id
      )

      broadcast_success_redirect(setup_intent_id, order.id)
    end
  end

  def log_order_processing_result(order, result)
    if result[:success]
      Rails.logger.info "Webhook (Thread): Successfully processed Order ##{order.id} with #{result[:processed].count} items"
    else
      Rails.logger.error "Webhook (Thread): Order ##{order.id} processing completed with #{result[:failed].count} failures"
      result[:failed].each do |failure|
        Rails.logger.error "  - Item #{failure[:item].id} (#{failure[:item].pos_product.name}): #{failure[:error].message}"
      end
    end
  end

  def create_subscription_from_payment_intent(order, payment_intent)
    subscription_item = order.order_items.find { |item| item.pos_product.product_type == 'subscription' }
    return unless subscription_item

    begin
      charge = Stripe::Charge.retrieve(payment_intent.latest_charge)
      generated_card_pm_id = charge.payment_method_details.card_present.generated_card
      customer_id = payment_intent.customer

      unless generated_card_pm_id
        Rails.logger.error "Webhook (Thread): Could not find a generated card for Order ##{order.id}."
        return
      end

      create_subscription_for_order(order, customer_id, generated_card_pm_id)

    rescue Stripe::StripeError => e
      Rails.logger.error "Webhook (Thread): Failed to create subscription for Order ##{order.id}. Error: #{e.message}"
      nil
    end
  end

  def create_subscription_for_order(order, customer_id, generated_card_pm_id)
    subscription_item = order.order_items.find { |item| item.pos_product.product_type == 'subscription' }
    return unless subscription_item

    unless customer_id && generated_card_pm_id
      Rails.logger.error "Webhook (Thread): Missing customer or generated card for Order ##{order.id}."
      return
    end

    attach_payment_method_to_customer(generated_card_pm_id, customer_id)
    Stripe::Customer.update(customer_id, { invoice_settings: { default_payment_method: generated_card_pm_id }})

    subscription = Stripe::Subscription.create({
      customer: customer_id,
      default_payment_method: generated_card_pm_id,
      items: [{ price: subscription_item.pos_product.stripe_price_id }],
      payment_settings: { payment_method_types: ['card'] },
      metadata: { order_id: order.id }
    })

    Rails.logger.info "Webhook (Thread): Successfully created Subscription #{subscription.id} for Order ##{order.id}"
    subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Webhook (Thread): Failed to create subscription for Order ##{order.id}. Error: #{e.message}"
    nil
  end

  def attach_payment_method_to_customer(payment_method_id, customer_id)
    Stripe::PaymentMethod.attach(payment_method_id, { customer: customer_id })
  rescue Stripe::InvalidRequestError => e
    raise unless e.message.match?(/already.*attach/i)
  end

  def retrieve_setup_intent(setup_intent_id, expand_latest_attempt: false)
    return Stripe::SetupIntent.retrieve(setup_intent_id) unless expand_latest_attempt

    Stripe::SetupIntent.retrieve({ id: setup_intent_id, expand: ['latest_attempt'] })
  end

  def generated_card_from_setup_intent(setup_intent)
    setup_intent.latest_attempt&.payment_method_details&.card_present&.generated_card
  end

  def handle_setup_failure(setup_intent)
    setup_intent_id = setup_intent.id
    order_id = order_id_from_metadata(setup_intent)

    Rails.logger.info "Setup failed for #{setup_intent_id}"
    return unless order_id

    record_terminal_failure(
      order_id,
      stripe_setup_intent_id: setup_intent_id,
      amount: 0
    )

    broadcast_failure_redirect(setup_intent_id, order_id)
  end

  def handle_payment_failure(payment_intent)
    payment_intent_id = payment_intent.id
    order_id = order_id_from_metadata(payment_intent)

    Rails.logger.info "Payment failed for #{payment_intent_id}"
    return unless order_id

    record_terminal_failure(
      order_id,
      payment_intent_id: payment_intent_id,
      amount: payment_intent.amount
    )

    broadcast_failure_redirect(payment_intent_id, order_id)
  end

  def record_terminal_failure(order_id, attrs)
    return unless order_id && Order.exists?(order_id)

    order = Order.find(order_id)
    order.with_lock do
      next if order.payment&.succeeded?

      payment = order.payment || order.build_payment
      payment.update!(
        {
          payment_method_type: 'card',
          status: 'failed'
        }.merge(attrs)
      )
    end
  end

  def order_id_from_metadata(intent)
    metadata = intent.metadata
    metadata && (metadata['order_id'] || metadata[:order_id])
  end

  def broadcast_success_redirect(intent_id, order_id)
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{intent_id}",
      target: "redirect_target",
      partial: "pos/redirect",
      locals: { url: pos_success_path(order_id: order_id) }
    )
  end

  def broadcast_failure_redirect(intent_id, order_id)
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{intent_id}",
      target: "redirect_target",
      partial: "pos/redirect",
      locals: { url: pos_failure_path(order_id: order_id) }
    )
  end
end
