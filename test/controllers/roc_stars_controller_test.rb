require "test_helper"

class RocStarsControllerTest < ActionDispatch::IntegrationTest
  test "should get prices" do
    get roc_stars_prices_url
    assert_response :success
  end

  test "should get create_checkout_session:post" do
    get roc_stars_create_checkout_session:post_url
    assert_response :success
  end

  test "should get new" do
    get new_session_roc_stars_url
    assert_response :success
  end

  test "should create checkout session" do
    post create_checkout_session_roc_stars_url, params: { plan: 'monthly' }
    assert_response :success
  end
end
