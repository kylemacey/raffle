class CreateCheckoutSessionService
  attr_reader :params, :error, :response, :customer

  def initialize(params, request:)
    @params = params
    @request = request
    @error = nil
    @response = nil
    @customer = nil
  end

  def create_checkout_session
    return false unless valid_params?

    exact_price, closest_price = find_prices
    return false if closest_price.nil?

    @customer = find_or_create_customer
    return false unless customer

    create_session(exact_price, closest_price)
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

  def find_prices
    all_prices_for_interval = RocStarPrice.where(interval: @interval_type).to_a
    exact_price = all_prices_for_interval.find { |p| p.amount == @amount }
    closest_price = if exact_price
      exact_price
    else
      all_prices_for_interval.select { |p| p.amount <= @amount }.max_by(&:amount)
    end

    if closest_price.nil?
      min_price = all_prices_for_interval.min_by(&:amount)
      @error = if min_price
                 "Amount must be at least #{number_to_currency(min_price.amount / 100.0)}."
               else
                 "No suitable price found for this interval."
               end
      return nil, nil
    end

    [exact_price, closest_price]
  end

  def find_or_create_customer
    return unless params[:email].present?

    customer = Stripe::Customer.list(email: params[:email], limit: 1).data.first

    customer || Stripe::Customer.create(
      email: params[:email],
      name: params[:name]
    )
  rescue Stripe::StripeError => e
    @error = "Failed to create/find customer: #{e.message}"
    nil
  end

  def create_session(exact_price, closest_price)
    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [build_line_item(exact_price, closest_price)],
      mode: 'subscription',
      success_url: "#{@request.base_url}/roc_stars/success",
      cancel_url: "#{@request.base_url}/roc_stars/cancel"
    )

    @response = {
      session_id: session.id,
      checkout_url: session.url
    }
  end

  def build_line_item(exact_price, closest_price)
    if exact_price
      { price: exact_price.stripe_price_id, quantity: 1 }
    else
      {
        price_data: {
          currency: 'usd',
          product: closest_price.stripe_product_id,
          unit_amount: @amount,
          recurring: { interval: @interval_type, interval_count: 1 }
        },
        quantity: 1
      }
    end
  end

  # Helper to use in error messages
  def number_to_currency(number)
    ActiveSupport::NumberHelper.number_to_currency(number)
  end
end