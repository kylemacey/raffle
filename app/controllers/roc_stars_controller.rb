class RocStarsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_all_prices

  def prices
    @prices = RocStarPrice.all

    respond_to do |format|
      format.json { @prices.to_json }
    end
  end

  def create_checkout_session
    amount = params[:amount].to_i
    email = params[:email]
    name = params[:name]
    interval_type = params[:interval_type] # 'year' or 'month'

    # Find exact price match or closest lower price
    exact_price = @all_prices.find { |p| p.amount == amount && p.interval == interval_type }
    closest_price = if exact_price
      exact_price
    else
      @all_prices
        .select { |p| p.amount <= amount && p.interval == interval_type }
        .max_by(&:amount)
    end

    if closest_price.nil?
      respond_to do |format|
        format.json { render json: { error: "No suitable price found" }, status: :bad_request }
      end
      return
    end

    begin
      # Find or create Stripe customer
      customers = Stripe::Customer.list(email: email, limit: 1)
      customer = if customers.data.any?
        customers.data.first
      else
        Stripe::Customer.create(
          email: email,
          name: name
        )
      end

      # Prepare Stripe checkout session parameters
      session_params = {
        customer: customer.id,
        mode: 'subscription',
        success_url: request.base_url + '/success',
        cancel_url: request.base_url + '/cancel',
        line_items: [build_line_item(exact_price, closest_price, amount, interval_type)]
      }

      session = Stripe::Checkout::Session.create(session_params)

      respond_to do |format|
        format.json { render json: {
          session_id: session.id,
          checkout_url: session.url
        } }
      end
    rescue Stripe::StripeError => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_all_prices
    @all_prices = RocStarPrice.all
  end

  def build_line_item(exact_price, closest_price, amount, interval_type)
    if exact_price
      {
        price: exact_price.stripe_price_id,
        quantity: 1
      }
    else
      {
        price_data: {
          currency: 'usd',
          product: closest_price.stripe_product_id,
          unit_amount: amount,
          recurring: {
            interval: interval_type,
            interval_count: 1
          }
        },
        quantity: 1
      }
    end
  end
end
