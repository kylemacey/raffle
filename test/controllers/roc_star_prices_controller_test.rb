require "test_helper"

class RocStarPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @roc_star_price = roc_star_prices(:monthly_10)
    sign_in(users(:admin))
  end

  test "should get index" do
    get roc_star_prices_url
    assert_response :success
  end

  test "should get new" do
    get new_roc_star_price_url
    assert_response :success
  end

  test "should create roc_star_price" do
    assert_difference("RocStarPrice.count") do
      post roc_star_prices_url, params: { roc_star_price: { amount: 3500, description: @roc_star_price.description, interval: @roc_star_price.interval, name: "Monthly Plan $35", stripe_product_id: "prod_monthly_35", stripe_price_id: "price_monthly_35" } }
    end

    assert_redirected_to roc_star_price_url(RocStarPrice.last)
  end

  test "should show roc_star_price" do
    get roc_star_price_url(@roc_star_price)
    assert_response :success
  end

  test "should get edit" do
    get edit_roc_star_price_url(@roc_star_price)
    assert_response :success
  end

  test "should update roc_star_price" do
    patch roc_star_price_url(@roc_star_price), params: { roc_star_price: { amount: @roc_star_price.amount, description: @roc_star_price.description, interval: @roc_star_price.interval, name: @roc_star_price.name, stripe_product_id: @roc_star_price.stripe_product_id, stripe_price_id: @roc_star_price.stripe_price_id } }
    assert_redirected_to roc_star_price_url(@roc_star_price)
  end

  test "should destroy roc_star_price" do
    assert_difference("RocStarPrice.count", -1) do
      delete roc_star_price_url(@roc_star_price)
    end

    assert_redirected_to roc_star_prices_url
  end
end
