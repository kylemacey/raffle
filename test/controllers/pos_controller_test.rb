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

  test "should get create_order" do
    post pos_create_order_path
    assert_response :success
  end

  test "should get success" do
    get pos_success_path(order_id: orders(:one).id)
    assert_response :success
  end
end
