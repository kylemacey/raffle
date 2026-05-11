require "test_helper"

class SilentAuctionBidTest < ActiveSupport::TestCase
  test "requires an open item" do
    bid = silent_auction_items(:paused_item).silent_auction_bids.build(
      bidder_name: "Buyer",
      bidder_phone: "585-555-0102",
      bidder_email: "buyer@example.com",
      amount_cents: 2500,
      commitment_confirmation: "1"
    )

    assert_not bid.valid?
    assert_includes bid.errors[:base], "This item is not accepting bids."
  end

  test "requires minimum bid" do
    item = silent_auction_items(:open_item)
    bid = item.silent_auction_bids.build(
      bidder_name: "Buyer",
      bidder_phone: "585-555-0102",
      bidder_email: "BUYER@example.com",
      formatted_amount: "99.99",
      commitment_confirmation: "1",
      minimum_bid_cents: item.next_minimum_bid_cents
    )

    assert_not bid.valid?
    assert_includes bid.errors[:amount_cents], "must be at least $100.00"
    assert_equal "buyer@example.com", bid.bidder_email
  end

  test "requires commitment confirmation" do
    item = silent_auction_items(:open_item)
    bid = item.silent_auction_bids.build(
      bidder_name: "Buyer",
      bidder_phone: "585-555-0102",
      bidder_email: "buyer@example.com",
      amount_cents: item.next_minimum_bid_cents,
      minimum_bid_cents: item.next_minimum_bid_cents
    )

    assert_not bid.valid?
    assert_includes bid.errors[:commitment_confirmation], "must be accepted"
  end

  test "requires exactly ten phone digits" do
    item = silent_auction_items(:open_item)
    bid = item.silent_auction_bids.build(
      bidder_name: "Buyer",
      bidder_phone: "555-0102",
      bidder_email: "buyer@example.com",
      amount_cents: item.next_minimum_bid_cents,
      commitment_confirmation: "1",
      minimum_bid_cents: item.next_minimum_bid_cents
    )

    assert_not bid.valid?
    assert_includes bid.errors[:bidder_phone], "must contain exactly 10 digits"
  end

  test "rejects unsupported phone characters" do
    item = silent_auction_items(:open_item)
    bid = item.silent_auction_bids.build(
      bidder_name: "Buyer",
      bidder_phone: "585.555.0102",
      bidder_email: "buyer@example.com",
      amount_cents: item.next_minimum_bid_cents,
      commitment_confirmation: "1",
      minimum_bid_cents: item.next_minimum_bid_cents
    )

    assert_not bid.valid?
    assert_includes bid.errors[:bidder_phone], "can only include digits, spaces, parentheses, and hyphens"
  end

  test "formats valid phone numbers before save" do
    item = silent_auction_items(:open_item)
    bid = item.silent_auction_bids.create!(
      bidder_name: "Buyer",
      bidder_phone: "5855550102",
      bidder_email: "buyer@example.com",
      amount_cents: item.next_minimum_bid_cents,
      commitment_confirmation: "1",
      minimum_bid_cents: item.next_minimum_bid_cents
    )

    assert_equal "(585) 555-0102", bid.bidder_phone
  end
end
