require "test_helper"
require "minitest/mock"
require "ostruct"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
    @user = users(:one)
  end

  test "terminal reader payment intent success records payment" do
    order = build_order_with_items([[pos_products(:one), 1]])
    payment_intent = OpenStruct.new(
      id: "pi_webhook_123",
      metadata: { "order_id" => order.id.to_s },
      amount: 100,
      latest_charge: "ch_unused",
      customer: "cus_unused"
    )
    event = terminal_event(
      "terminal.reader.action_succeeded",
      "process_payment_intent",
      "payment_intent",
      payment_intent.id
    )

    with_sync_thread do
      with_broadcast_stub do
        Stripe::Webhook.stub(:construct_event, event) do
          Stripe::PaymentIntent.stub(:retrieve, payment_intent) do
            Stripe::PaymentIntent.stub(:capture, OpenStruct.new(id: payment_intent.id)) do
              post "/webhooks/stripe", params: "{}"
            end
          end
        end
      end
    end

    assert_response :success
    payment = order.reload.payment
    assert_equal "card", payment.payment_method_type
    assert_equal "100", payment.amount
    assert_equal "pi_webhook_123", payment.payment_intent_id
    assert_equal "succeeded", payment.status
  end

  test "terminal reader setup intent success creates subscription payment tracking" do
    order = build_order_with_items([[pos_products(:two), 1]])
    setup_intent = OpenStruct.new(
      id: "seti_webhook_123",
      metadata: { "order_id" => order.id.to_s },
      customer: "cus_setup_123",
      latest_attempt: OpenStruct.new(
        payment_method_details: OpenStruct.new(
          card_present: OpenStruct.new(generated_card: "pm_generated_123")
        )
      )
    )
    event = terminal_event(
      "terminal.reader.action_succeeded",
      "process_setup_intent",
      "setup_intent",
      setup_intent.id
    )
    subscription = OpenStruct.new(id: "sub_webhook_123")
    broadcasts = []
    setup_retrieve_arg = nil

    with_sync_thread do
      with_broadcast_stub(broadcasts) do
        Stripe::Webhook.stub(:construct_event, event) do
          Stripe::SetupIntent.stub(:retrieve, ->(arg) { setup_retrieve_arg = arg; setup_intent }) do
            Stripe::PaymentMethod.stub(:attach, OpenStruct.new(id: "pm_generated_123")) do
              Stripe::Customer.stub(:update, OpenStruct.new(id: "cus_setup_123")) do
                Stripe::Subscription.stub(:create, subscription) do
                  post "/webhooks/stripe", params: "{}"
                end
              end
            end
          end
        end
      end
    end

    assert_response :success
    assert_equal({ id: setup_intent.id, expand: ['latest_attempt'] }, setup_retrieve_arg)
    payment = order.reload.payment
    assert_equal "card", payment.payment_method_type
    assert_equal "0", payment.amount
    assert_equal "seti_webhook_123", payment.stripe_setup_intent_id
    assert_equal "sub_webhook_123", payment.stripe_subscription_id
    assert_equal "succeeded", payment.status
    assert_equal "payment_status_seti_webhook_123", broadcasts.last.first.first
    assert_includes broadcasts.last.last[:locals][:url], "/pos/success/#{order.id}"
  end

  test "terminal reader setup intent success without generated card records failure" do
    order = build_order_with_items([[pos_products(:two), 1]])
    setup_intent = OpenStruct.new(
      id: "seti_missing_card",
      metadata: { "order_id" => order.id.to_s },
      customer: "cus_setup_123",
      latest_attempt: OpenStruct.new(
        payment_method_details: OpenStruct.new(
          card_present: OpenStruct.new(generated_card: nil)
        )
      )
    )
    event = terminal_event(
      "terminal.reader.action_succeeded",
      "process_setup_intent",
      "setup_intent",
      setup_intent.id
    )
    broadcasts = []
    setup_retrieve_arg = nil

    with_sync_thread do
      with_broadcast_stub(broadcasts) do
        Stripe::Webhook.stub(:construct_event, event) do
          Stripe::SetupIntent.stub(:retrieve, ->(arg) { setup_retrieve_arg = arg; setup_intent }) do
            post "/webhooks/stripe", params: "{}"
          end
        end
      end
    end

    assert_response :success
    assert_equal({ id: setup_intent.id, expand: ['latest_attempt'] }, setup_retrieve_arg)
    payment = order.reload.payment
    assert_equal "seti_missing_card", payment.stripe_setup_intent_id
    assert_equal "failed", payment.status
    assert_nil payment.stripe_subscription_id
    assert_equal "payment_status_seti_missing_card", broadcasts.last.first.first
    assert_includes broadcasts.last.last[:locals][:url], "/pos/failure/#{order.id}"
  end

  private

  def build_order_with_items(items)
    total = items.sum { |product, quantity| product.price * quantity }
    order = @event.orders.create!(
      customer_name: "Webhook Customer",
      customer_email: "webhook@example.com",
      total_amount: total,
      user: @user,
      payment_method_type: "card"
    )

    items.each do |product, quantity|
      order.order_items.create!(
        pos_product: product,
        quantity: quantity,
        unit_price: product.price
      )
    end

    order
  end

  def terminal_event(event_type, action_type, intent_key, intent_id)
    {
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

  def with_sync_thread(&block)
    Thread.stub(:new, ->(*_args, &thread_block) { thread_block.call }, &block)
  end

  def with_broadcast_stub(broadcasts = [], &block)
    Turbo::StreamsChannel.stub(
      :broadcast_replace_to,
      ->(*args, **kwargs) {
        broadcasts << [args, kwargs]
      },
      &block
    )
  end
end
