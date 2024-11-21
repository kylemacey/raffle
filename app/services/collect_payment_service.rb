class CollectPaymentService
  attr_reader :amount, :customer, :reader, :metadata

  def self.call(**params)
    new(**params).call
  end

  def initialize(amount:, customer: {}, reader:, metadata: nil)
    @amount, @reader, @metadata = amount, reader, metadata

    @customer = customer.with_indifferent_access.slice(:name, :email)
  end

  def call
    stripe_customer = find_or_create_customer

    payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      payment_method_types: ['card_present'],
      capture_method: 'manual',
      customer: stripe_customer,
      metadata: metadata,
    )

    reader.process_payment_intent({payment_intent: payment_intent})
  end

private

  def find_or_create_customer
    return unless customer.has_key?(:name) || customer.has_key?(:email)
    (customer.has_key?(:email) && Stripe::Customer.search(query: "email:'#{customer[:email]}'", limit: 1).first) ||
      Stripe::Customer.create(customer)

  end
end