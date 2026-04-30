require "test_helper"
require "minitest/mock"
require "ostruct"

class CollectPaymentServiceTest < ActiveSupport::TestCase
  class FakeReader
    attr_reader :processed_payment_intent, :processed_setup_intent

    def process_payment_intent(params)
      @processed_payment_intent = params
    end

    def process_setup_intent(params)
      @processed_setup_intent = params
    end
  end

  setup do
    @event = events(:one)
    @user = users(:one)
    @customer = OpenStruct.new(id: "cus_test_123")
  end

  test "creates a payment intent for one-time-only orders" do
    order = build_order_with_items([[pos_products(:one), 2]])
    reader = FakeReader.new
    payment_intent_params = nil

    with_customer_stubs do
      Stripe::PaymentIntent.stub(:create, ->(params) {
        payment_intent_params = params
        OpenStruct.new(id: "pi_test_123")
      }) do
        service = CollectPaymentService.new(order: order, reader: reader)
        service.collect_payment

        assert service.success?
        assert_equal "payment_intent", service.intent_type
      end
    end

    assert_equal 200, payment_intent_params[:amount]
    assert_nil payment_intent_params[:setup_future_usage]
    assert_equal "cus_test_123", payment_intent_params[:customer]
    assert_equal "pi_test_123", reader.processed_payment_intent[:payment_intent].id
  end

  test "creates a payment intent with future usage for mixed subscription orders" do
    order = build_order_with_items([[pos_products(:one), 1], [pos_products(:two), 1]])
    reader = FakeReader.new
    payment_intent_params = nil

    with_customer_stubs do
      Stripe::PaymentIntent.stub(:create, ->(params) {
        payment_intent_params = params
        OpenStruct.new(id: "pi_test_mixed")
      }) do
        service = CollectPaymentService.new(order: order, reader: reader)
        service.collect_payment
      end
    end

    assert_equal 100, payment_intent_params[:amount]
    assert_equal "off_session", payment_intent_params[:setup_future_usage]
    assert_nil reader.processed_setup_intent
  end

  test "creates a setup intent for subscription-only orders" do
    order = build_order_with_items([[pos_products(:two), 1]])
    reader = FakeReader.new
    setup_intent_params = nil

    with_customer_stubs do
      Stripe::SetupIntent.stub(:create, ->(params) {
        setup_intent_params = params
        OpenStruct.new(id: "seti_test_123")
      }) do
        service = CollectPaymentService.new(order: order, reader: reader)
        service.collect_payment

        assert service.success?
        assert_equal "setup_intent", service.intent_type
        assert_equal "seti_test_123", service.intent_id
      end
    end

    assert_equal ["card_present"], setup_intent_params[:payment_method_types]
    assert_equal "off_session", setup_intent_params[:usage]
    assert_equal "cus_test_123", setup_intent_params[:customer]
    assert_equal({ order_id: order.id }, setup_intent_params[:metadata])
    assert_equal "seti_test_123", reader.processed_setup_intent[:setup_intent]
    assert_equal "limited", reader.processed_setup_intent[:allow_redisplay]
    assert_equal true, reader.processed_setup_intent[:process_config][:enable_customer_cancellation]
  end

  private

  def build_order_with_items(items)
    total = items.sum { |product, quantity| product.price * quantity }
    order = @event.orders.create!(
      customer_name: "Test Customer",
      customer_email: "test@example.com",
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

  def with_customer_stubs(&block)
    Stripe::Customer.stub(:search, []) do
      Stripe::Customer.stub(:create, @customer, &block)
    end
  end
end
