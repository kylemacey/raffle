require "test_helper"

class RocStarPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @roc_star_price = roc_star_prices(:one)
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
      post roc_star_prices_url, params: { roc_star_price: { amount: @roc_star_price.amount, description: @roc_star_price.description, interval: @roc_star_price.interval, name: @roc_star_price.name, product_id: @roc_star_price.product_id } }
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
    patch roc_star_price_url(@roc_star_price), params: { roc_star_price: { amount: @roc_star_price.amount, description: @roc_star_price.description, interval: @roc_star_price.interval, name: @roc_star_price.name, product_id: @roc_star_price.product_id } }
    assert_redirected_to roc_star_price_url(@roc_star_price)
  end

  test "should destroy roc_star_price" do
    assert_difference("RocStarPrice.count", -1) do
      delete roc_star_price_url(@roc_star_price)
    end

    assert_redirected_to roc_star_prices_url
  end
end
