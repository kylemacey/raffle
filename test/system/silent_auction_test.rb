require "application_system_test_case"

class SilentAuctionTest < ApplicationSystemTestCase
  setup do
    @event = events(:one)
  end

  test "buyer can place public bid" do
    visit event_public_silent_auction_url(@event)
    click_on "Weekend Getaway"

    fill_in "Name", with: "System Bidder"
    fill_in "Phone", with: "5855550110"
    fill_in "Email", with: "system@example.com"
    fill_in "Bid amount", with: "100.00"
    check "I agree to pay this bid if I win."
    click_on "Place bid"

    assert_text "Bid placed"
    assert_text "$100.00"
  end

  test "event lead can create silent auction item" do
    sign_in(users(:two))

    visit event_silent_auction_items_url(@event)
    click_on "New item", match: :first

    fill_in "Name", with: "System Prize"
    fill_in "Description", with: "Created from a system test."
    fill_in "Starting bid", with: "45.00"
    fill_in "Image URL", with: "https://example.com/system-prize.jpg"
    click_on "Create Silent auction item"

    assert_text "Silent auction item was created"
    assert_text "System Prize"
  end
end
