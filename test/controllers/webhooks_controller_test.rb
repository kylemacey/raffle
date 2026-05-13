require "test_helper"
require "minitest/mock"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "valid Stripe webhook enqueues processing job without performing Stripe work inline" do
    event = terminal_event(
      "terminal.reader.action_succeeded",
      "process_payment_intent",
      "payment_intent",
      "pi_webhook_123"
    )

    assert_enqueued_jobs 1, only: StripeWebhookEventJob do
      Stripe::Webhook.stub(:construct_event, event) do
        Stripe::PaymentIntent.stub(:retrieve, ->(*) { raise "should not retrieve payment intent inline" }) do
          post "/webhooks/stripe", params: "{}"
        end
      end
    end

    assert_response :success
  end

  test "invalid Stripe webhook signature returns bad request and does not enqueue job" do
    assert_no_enqueued_jobs only: StripeWebhookEventJob do
      Stripe::Webhook.stub(:construct_event, ->(*) { raise JSON::ParserError, "bad payload" }) do
        post "/webhooks/stripe", params: "{"
      end
    end

    assert_response :bad_request
  end

  private

  def terminal_event(event_type, action_type, intent_key, intent_id)
    {
      "id" => "evt_test_123",
      "type" => event_type,
      "data" => {
        "object" => {
          "action" => {
            "type" => action_type,
            action_type => {
              intent_key => intent_id
            }
          }
        }
      }
    }
  end
end
