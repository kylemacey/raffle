require "test_helper"

class SilentAuctionItemTest < ActiveSupport::TestCase
  test "defaults to draft" do
    item = events(:one).silent_auction_items.build(
      name: "New Prize",
      description: "A donated prize.",
      formatted_starting_bid: "25.00",
      image_url: "https://example.com/prize.jpg"
    )

    assert item.valid?
    assert_equal "draft", item.status
    assert_equal 2500, item.starting_bid_cents
  end

  test "current and next bid use highest bid plus configured increment" do
    item = silent_auction_items(:open_item)

    assert_equal 7500, item.current_bid_cents
    assert_equal 10000, item.next_minimum_bid_cents
  end

  test "first bid starts at starting bid" do
    item = silent_auction_items(:paused_item)

    assert_equal item.starting_bid_cents, item.next_minimum_bid_cents
  end

  test "public listing excludes draft items" do
    assert_includes SilentAuctionItem.publicly_listed, silent_auction_items(:paused_item)
    assert_not_includes SilentAuctionItem.publicly_listed, silent_auction_items(:draft_item)
  end

  test "bid count ignores unsaved form bids" do
    item = silent_auction_items(:open_item)
    item.silent_auction_bids.load
    item.silent_auction_bids.build(
      bidder_name: "Unsaved Bidder",
      bidder_phone: "585-555-0107",
      bidder_email: "unsaved@example.com",
      amount_cents: 10000
    )

    assert_equal 2, item.bid_count
  end
end
