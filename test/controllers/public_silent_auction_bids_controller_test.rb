require "test_helper"

class PublicSilentAuctionBidsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
    @item = silent_auction_items(:open_item)
  end

  test "creates public bid at minimum amount" do
    assert_difference("SilentAuctionBid.count") do
      post event_public_silent_auction_item_bids_url(@event, @item), params: {
        silent_auction_bid: {
          bidder_name: "New Bidder",
          bidder_phone: "5855550104",
          bidder_email: "NEW@example.com",
          formatted_amount: "100.00",
          commitment_confirmation: "1"
        }
      }
    end

    assert_redirected_to event_public_silent_auction_item_url(@event, @item)
    assert_equal "new@example.com", SilentAuctionBid.last.bidder_email
    assert_equal "(585) 555-0104", SilentAuctionBid.last.bidder_phone
  end

  test "rejects bid below minimum" do
    assert_no_difference("SilentAuctionBid.count") do
      post event_public_silent_auction_item_bids_url(@event, @item), params: {
        silent_auction_bid: {
          bidder_name: "Low Bidder",
          bidder_phone: "585-555-0105",
          bidder_email: "low@example.com",
          formatted_amount: "99.99",
          commitment_confirmation: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "rejects bid with invalid phone number" do
    assert_no_difference("SilentAuctionBid.count") do
      post event_public_silent_auction_item_bids_url(@event, @item), params: {
        silent_auction_bid: {
          bidder_name: "Invalid Phone",
          bidder_phone: "555-0105",
          bidder_email: "invalid-phone@example.com",
          formatted_amount: "100.00",
          commitment_confirmation: "1"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Phone must contain exactly 10 digits"
  end

  test "rejects bid for paused item" do
    assert_raises ActiveRecord::RecordNotFound do
      post event_public_silent_auction_item_bids_url(@event, silent_auction_items(:paused_item)), params: {
        silent_auction_bid: {
          bidder_name: "Paused Bidder",
          bidder_phone: "585-555-0106",
          bidder_email: "paused@example.com",
          formatted_amount: "25.00",
          commitment_confirmation: "1"
        }
      }
    end
  end
end
