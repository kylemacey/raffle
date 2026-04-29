require "test_helper"
require "minitest/mock"
require "ostruct"

class PosControllerTest < ActionDispatch::IntegrationTest
  class FakeReader
    attr_reader :processed_setup_intent

    def id
      "tmr_test_123"
    end

    def label
      "Test Reader"
    end

    def status
      "online"
    end

    def deleted?
      false
    end

    def process_setup_intent(params)
      @processed_setup_intent = params
    end
  end

  setup do
    sign_in(users(:one))
    post pos_create_path, params: { event_id: events(:one).id }
  end

  test "should get main" do
    get pos_main_path
    assert_response :success
  end

  test "should get checkout" do
    post pos_checkout_path
    assert_response :redirect
  end

  test "card checkout without reader redirects to reader selection" do
    post pos_checkout_path, params: {
      name: "Test Customer",
      email: "test@example.com",
      payment_method: "card",
      cart_data: { pos_products(:one).id => 1 }.to_json
    }

    assert_redirected_to readers_list_path
  end

  test "card checkout allows subscription-only cart using setup intent" do
    reader = FakeReader.new
    customer = OpenStruct.new(id: "cus_setup_only")
    setup_intent = OpenStruct.new(id: "seti_checkout_123")

    post readers_assign_path, params: { reader_id: reader.id }

    Stripe::Terminal::Reader.stub(:retrieve, reader) do
      Stripe::Customer.stub(:search, []) do
        Stripe::Customer.stub(:create, customer) do
          Stripe::SetupIntent.stub(:create, setup_intent) do
            post pos_checkout_path, params: {
              name: "Setup Customer",
              email: "setup@example.com",
              payment_method: "card",
              cart_data: { pos_products(:two).id => 1 }.to_json
            }
          end
        end
      end
    end

    assert_redirected_to pos_wait_for_pin_pad_path("seti_checkout_123")
    assert_equal "seti_checkout_123", reader.processed_setup_intent[:setup_intent]
    assert_equal "limited", reader.processed_setup_intent[:allow_redisplay]
  end

  test "should get create_order" do
    post pos_create_order_path
    assert_response :success
  end

  test "should get success" do
    get pos_success_path(order_id: orders(:one).id)
    assert_response :success
  end
end
