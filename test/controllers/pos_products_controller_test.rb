require "test_helper"

class PosProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pos_product = pos_products(:one)
    sign_in(users(:admin))
  end

  test "should get index" do
    get pos_products_url
    assert_response :success
  end

  test "should get show" do
    get pos_product_url(@pos_product)
    assert_response :success
  end

  test "should get new" do
    get new_pos_product_url
    assert_response :success
  end

  test "should create pos product" do
    assert_difference("PosProduct.count") do
      post pos_products_url, params: { pos_product: { active: true, description: "Fixture product", formatted_price: "12.50", name: "Fixture Product", product_type: "raffle", stripe_price_id: "price_fixture", stripe_product_id: "prod_fixture", configuration: { tickets_per_unit: 2 } } }
    end

    assert_redirected_to pos_product_url(PosProduct.last)
  end

  test "should get edit" do
    get edit_pos_product_url(@pos_product)
    assert_response :success
  end

  test "should update pos product" do
    patch pos_product_url(@pos_product), params: { pos_product: { active: @pos_product.active, description: @pos_product.description, formatted_price: "15.00", name: @pos_product.name, product_type: @pos_product.product_type, stripe_price_id: @pos_product.stripe_price_id, stripe_product_id: @pos_product.stripe_product_id, configuration: @pos_product.configuration } }
    assert_redirected_to pos_product_url(@pos_product)
  end

  test "should destroy pos product" do
    pos_product = PosProduct.create!(name: "Temporary Product", price: 100, product_type: "raffle")

    assert_difference("PosProduct.count", -1) do
      delete pos_product_url(pos_product)
    end

    assert_redirected_to pos_products_url
  end
end
