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
    # Extract the Payment Intent ID
    payment_intent_id = payment_intent['id']
    Rails.logger.info "Payment succeeded for #{payment_intent_id}"

    # Broadcast success to the Turbo Stream
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{payment_intent_id}",
      target: "payment_status_#{payment_intent_id}",
      partial: "payments/status",
      locals: { status: "succeeded" }
    )

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        if payment_intent['status'] == 'requires_capture'
          metadata = payment_intent['metadata']
          entry = Entry.create!(
            event_id: metadata[:event],
            name: metadata[:name],
            phone: metadata[:email],
            qty: metadata[:qty],
          )
          Stripe::PaymentIntent.capture(payment_intent_id)
          Payment.create!(
            entry: entry,
            payment_method_type: "card",
            amount: payment_intent['amount'],
            payment_intent_id: payment_intent_id
          )
        end
      end
    end
  end

  def handle_payment_failure(payment_intent)
    # Extract the Payment Intent ID
    payment_intent_id = payment_intent['id']
    Rails.logger.info "Payment failed for #{payment_intent_id}"

    # Broadcast failure to the Turbo Stream
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_status_#{payment_intent_id}",
      target: "payment_status_#{payment_intent_id}",
      partial: "payments/status",
      locals: { status: "failed" }
    )
  end
end
