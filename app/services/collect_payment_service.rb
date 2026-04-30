class CollectPaymentService
  attr_reader :order, :reader, :payment_intent, :setup_intent

  def initialize(order:, reader:)
    @reader = reader
    @order = order
  end

  def collect_payment
    return if reader.blank?

    stripe_customer = find_or_create_customer

    if subscription_only?
      collect_setup_intent(stripe_customer)
    else
      collect_payment_intent(stripe_customer)
    end
  end

  def intent
    payment_intent || setup_intent
  end

  def intent_id
    intent&.id
  end

  def intent_type
    setup_intent.present? ? "setup_intent" : "payment_intent"
  end

  def success?
    intent.present?
  end

private

  def collect_payment_intent(stripe_customer)
    params = {
      amount: one_time_items_total,
      currency: 'usd',
      payment_method_types: ['card_present'],
      capture_method: 'manual',
      customer: stripe_customer_id(stripe_customer),
      metadata: { order_id: order.id }
    }

    if subscription_present?
      params[:setup_future_usage] = 'off_session'
    end

    @payment_intent = Stripe::PaymentIntent.create(params)

    reader.process_payment_intent({
      payment_intent: payment_intent,
      process_config: {
        allow_redisplay: 'limited',
        enable_customer_cancellation: true,
      }
    })
  end

  def collect_setup_intent(stripe_customer)
    @setup_intent = Stripe::SetupIntent.create(
      payment_method_types: ['card_present'],
      usage: 'off_session',
      customer: stripe_customer_id(stripe_customer),
      metadata: { order_id: order.id }
    )

    reader.process_setup_intent({
      setup_intent: setup_intent.id,
      allow_redisplay: 'limited',
      process_config: {
        enable_customer_cancellation: true,
      }
    })
  end

  def subscription_present?
    order.order_items.any? { |item| item.pos_product.product_type == 'subscription' }
  end

  def subscription_only?
    subscription_present? && one_time_items_total.zero?
  end

  def one_time_items_total
    order.order_items.reject { |item| item.pos_product.product_type == 'subscription' }
      .sum { |item| item.unit_price * item.quantity }
  end

  def stripe_customer_id(stripe_customer)
    stripe_customer.respond_to?(:id) ? stripe_customer.id : stripe_customer
  end

  def find_or_create_customer
    customer_details = order.customer_details
    return unless customer_details.has_key?(:name) || customer_details.has_key?(:email)
    (customer_details.has_key?(:email) && Stripe::Customer.search(query: "email:'#{customer_details[:email]}'", limit: 1).first) ||
      Stripe::Customer.create(customer_details)
  end
end
