class CollectPaymentService
  attr_reader :order, :reader, :payment_intent

  def initialize(order:, reader:)
    @reader = reader
    @order = order
  end

  def collect_payment
    return if reader.blank?

    stripe_customer = find_or_create_customer

    params = {
      amount: one_time_items_total,
      currency: 'usd',
      payment_method_types: ['card_present'],
      capture_method: 'manual',
      customer: stripe_customer,
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

  def success?
    payment_intent.present?
  end

private

  def subscription_present?
    order.order_items.any? { |item| item.pos_product.product_type == 'subscription' }
  end

  def one_time_items_total
    order.order_items.reject { |item| item.pos_product.product_type == 'subscription' }
      .sum { |item| item.unit_price * item.quantity }
  end

  def find_or_create_customer
    customer_details = order.customer_details
    return unless customer_details.has_key?(:name) || customer_details.has_key?(:email)
    (customer_details.has_key?(:email) && Stripe::Customer.search(query: "email:'#{customer_details[:email]}'", limit: 1).first) ||
      Stripe::Customer.create(customer_details)
  end
end
