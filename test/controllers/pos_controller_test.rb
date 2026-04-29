require "test_helper"

class PosControllerTest < ActionDispatch::IntegrationTest
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

  test "should get create_order" do
    post pos_create_order_path
    assert_response :success
  end

  test "should get success" do
    get pos_success_path(order_id: orders(:one).id)
    assert_response :success
  end
end
