require "test_helper"

class PosControllerTest < ActionDispatch::IntegrationTest
  test "should get main" do
    get pos_main_url
    assert_response :success
  end

  test "should get checkout" do
    get pos_checkout_url
    assert_response :success
  end

  test "should get create_order:post" do
    get pos_create_order:post_url
    assert_response :success
  end

  test "should get success" do
    get pos_success_url
    assert_response :success
  end
end
