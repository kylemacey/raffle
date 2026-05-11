require "test_helper"

class PublicSilentAuctionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
  end

  test "public index is available without sign in" do
    get event_public_silent_auction_url(@event)

    assert_response :success
    assert_select "h1", "Silent Auction"
  end

  test "public show is available for open item" do
    get event_public_silent_auction_item_url(@event, silent_auction_items(:open_item))

    assert_response :success
    assert_select "h1", "Weekend Getaway"
    assert_includes response.body, "Bids"
    assert_no_match "Second Bidder", response.body
    assert_no_match "second@example.com", response.body
  end

  test "public show is available for paused item without bid form" do
    get event_public_silent_auction_item_url(@event, silent_auction_items(:paused_item))

    assert_response :success
    assert_select "h2", "Bidding is paused."
    assert_select "form", count: 0
  end

  test "draft item is not publicly visible" do
    assert_raises ActiveRecord::RecordNotFound do
      get event_public_silent_auction_item_url(@event, silent_auction_items(:draft_item))
    end
  end
end
