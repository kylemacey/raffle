class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    event = Stripe::Webhook.construct_event(
      payload, sig_header, ENV["STRIPE_ENDPOINT_SECRET"]
    )

    StripeWebhookEventJob.perform_later(serialized_event(event))

    render json: { status: "received" }, status: :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe webhook error: #{e.message}"
    render json: { error: e.message }, status: :bad_request
  end

  private

  def serialized_event(event)
    {
      "id" => stripe_object_value(event, :id),
      "type" => stripe_object_value(event, :type),
      "data" => {
        "object" => stripe_object_to_plain_hash(stripe_data_object(event))
      }
    }
  end

  def stripe_data_object(event)
    data = stripe_object_value(event, :data)
    stripe_object_value(data, :object)
  end

  def stripe_object_to_plain_hash(object)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[key.to_s] = stripe_object_to_plain_hash(value)
      end
    when Array
      object.map { |value| stripe_object_to_plain_hash(value) }
    else
      if object.respond_to?(:to_hash)
        stripe_object_to_plain_hash(object.to_hash)
      else
        object
      end
    end
  end

  def stripe_object_value(object, key)
    if object.respond_to?(key)
      object.public_send(key)
    elsif object.respond_to?(:[])
      object[key.to_s] || object[key]
    end
  end
end
