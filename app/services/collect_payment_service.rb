class CollectPaymentService
  attr_reader :customer, :reader, :payment_intent
  def initialize(customer: {}, reader:)
    @reader = reader

    @customer = customer.with_indifferent_access.slice(:name, :email)
  end

  def collect_payment(amount, metadata: {})
    stripe_customer = find_or_create_customer

    @payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      payment_method_types: ['card_present'],
      capture_method: 'manual',
      customer: stripe_customer,
      metadata: metadata,
    )

    reader.process_payment_intent({
      payment_intent: payment_intent,
      process_config: {
        enable_customer_cancellation: true,
      }
    })
  end

  def success?
    payment_intent.present?
  end

private

  def find_or_create_customer
    return unless customer.has_key?(:name) || customer.has_key?(:email)
    (customer.has_key?(:email) && Stripe::Customer.search(query: "email:'#{customer[:email]}'", limit: 1).first) ||
      Stripe::Customer.create(customer)

  end
end