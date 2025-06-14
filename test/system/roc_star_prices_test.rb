require "application_system_test_case"

class RocStarPricesTest < ApplicationSystemTestCase
  setup do
    @roc_star_price = roc_star_prices(:one)
  end

  test "visiting the index" do
    visit roc_star_prices_url
    assert_selector "h1", text: "Roc star prices"
  end

  test "should create roc star price" do
    visit roc_star_prices_url
    click_on "New roc star price"

    fill_in "Amount", with: @roc_star_price.amount
    fill_in "Description", with: @roc_star_price.description
    fill_in "Interval", with: @roc_star_price.interval
    fill_in "Name", with: @roc_star_price.name
    fill_in "Stripe Product ID", with: @roc_star_price.stripe_product_id
    fill_in "Stripe Price ID", with: @roc_star_price.stripe_price_id
    click_on "Create Roc star price"

    assert_text "Roc star price was successfully created"
    click_on "Back"
  end

  test "should update Roc star price" do
    visit roc_star_price_url(@roc_star_price)
    click_on "Edit this roc star price", match: :first

    fill_in "Amount", with: @roc_star_price.amount
    fill_in "Description", with: @roc_star_price.description
    fill_in "Interval", with: @roc_star_price.interval
    fill_in "Name", with: @roc_star_price.name
    fill_in "Stripe Product ID", with: @roc_star_price.stripe_product_id
    fill_in "Stripe Price ID", with: @roc_star_price.stripe_price_id
    click_on "Update Roc star price"

    assert_text "Roc star price was successfully updated"
    click_on "Back"
  end

  test "should destroy Roc star price" do
    visit roc_star_price_url(@roc_star_price)
    click_on "Destroy this roc star price", match: :first

    assert_text "Roc star price was successfully destroyed"
  end
end
