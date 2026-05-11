require "test_helper"

class SilentAuctionCloseEventItemsServiceTest < ActiveSupport::TestCase
  test "closes open and paused items and leaves drafts alone" do
    event = events(:two)
    open_item = event.silent_auction_items.create!(
      name: "Open Prize",
      description: "Open prize.",
      starting_bid_cents: 1000,
      image_url: "https://example.com/open.jpg",
      status: "open"
    )
    paused_item = event.silent_auction_items.create!(
      name: "Paused Prize",
      description: "Paused prize.",
      starting_bid_cents: 2000,
      image_url: "https://example.com/paused.jpg",
      status: "paused"
    )
    draft_item = event.silent_auction_items.create!(
      name: "Draft Prize",
      description: "Draft prize.",
      starting_bid_cents: 3000,
      image_url: "https://example.com/draft.jpg"
    )

    result = SilentAuction::CloseEventItemsService.new(event).call

    assert result.success?
    assert_equal "closed", open_item.reload.status
    assert_equal "closed", paused_item.reload.status
    assert_equal "draft", draft_item.reload.status
  end
end
