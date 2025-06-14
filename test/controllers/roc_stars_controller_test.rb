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
end
