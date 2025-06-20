class CreateCheckoutSessionService
  attr_reader :params, :error, :response, :customer, :price

  def initialize(params, request:)
    @params = params
    @request = request
    @error = nil
    @response = nil
    @customer = nil
    @price = nil
  end

  def create_checkout_session
    return false unless valid_params?

    @price = find_price
    return false unless price

    @customer = find_or_create_customer
    return false unless customer

    create_session
    true
  rescue Stripe::StripeError => e
    @error = e.message
    false
  end

  def success?
    @error.nil?
  end

  def response
    @response
  end

  private

  def valid_params?
    return false unless params[:amount].present? && params[:email].present? && params[:name].present?

    @amount = params[:amount].to_i
    @interval_type = params[:interval_type]&.downcase
    true
  end

  def find_price
    # First try to find an exact match
    price = RocStarPrice.find_by(amount: @amount, interval: @interval_type)
    return price if price

    # If no exact match, find the closest lower price
    price = RocStarPrice.where(interval: @interval_type)
                        .where('amount <= ?', @amount)
                        .order(amount: :desc)
                        .first

    unless price
      @error = "No suitable price found"
      return nil
    end

    price
  end

  def find_or_create_customer
    return unless params[:email].present?

    customer = Stripe::Customer.list(email: params[:email], limit: 1).data.first

    unless customer
      customer = Stripe::Customer.create(
        email: params[:email],
        name: params[:name]
      )
    end

    customer
  rescue Stripe::StripeError => e
    @error = "Failed to create/find customer: #{e.message}"
    nil
  end

  def create_session
    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [build_line_item],
      mode: 'subscription',
      success_url: "#{@request.base_url}/success",
      cancel_url: "#{@request.base_url}/cancel"
    )

    @response = {
      session_id: session.id,
      checkout_url: session.url
    }
  rescue Stripe::StripeError => e
    @error = "Failed to create checkout session: #{e.message}"
    nil
  end

  def build_line_item
    {
      price: price.stripe_price_id,
      quantity: 1
    }
  end
end