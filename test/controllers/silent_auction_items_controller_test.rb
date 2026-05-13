require "test_helper"

class SilentAuctionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
    @item = silent_auction_items(:paused_item)
    sign_in(users(:two))
  end

  test "event lead can get index" do
    get event_silent_auction_items_url(@event)

    assert_response :success
    assert_select "button", "Open all (2)"
    assert_select "button", "Pause all (1)"
    assert_select "a", "Close all (2)"
  end

  test "event lead can create item" do
    assert_difference("SilentAuctionItem.count") do
      post event_silent_auction_items_url(@event), params: {
        silent_auction_item: {
          name: "New Prize",
          description: "New donated item.",
          formatted_starting_bid: "40.00",
          image_url: "https://example.com/new-prize.jpg"
        }
      }
    end

    assert_redirected_to event_silent_auction_item_url(@event, SilentAuctionItem.last)
    assert_equal "draft", SilentAuctionItem.last.status
  end

  test "event lead can open and pause item" do
    patch open_event_silent_auction_item_url(@event, @item)
    assert_redirected_to event_silent_auction_item_url(@event, @item)
    assert_equal "open", @item.reload.status

    patch pause_event_silent_auction_item_url(@event, @item)
    assert_redirected_to event_silent_auction_item_url(@event, @item)
    assert_equal "paused", @item.reload.status
  end

  test "event lead can open all draft and paused items" do
    patch open_all_event_silent_auction_items_url(@event)

    assert_redirected_to event_silent_auction_items_url(@event)
    assert_equal "open", silent_auction_items(:paused_item).reload.status
    assert_equal "open", silent_auction_items(:draft_item).reload.status
  end

  test "event lead can pause all open items" do
    patch pause_all_event_silent_auction_items_url(@event)

    assert_redirected_to event_silent_auction_items_url(@event)
    assert_equal "paused", silent_auction_items(:open_item).reload.status
    assert_equal "paused", silent_auction_items(:paused_item).reload.status
    assert_equal "draft", silent_auction_items(:draft_item).reload.status
  end

  test "event lead can review close confirmation" do
    get close_confirmation_event_silent_auction_item_url(@event, silent_auction_items(:open_item))

    assert_response :success
    assert_select "h1", "Close Item"
    assert_select "dd", text: /Second Bidder/
    assert_select "dd", text: "Card, ACH direct debit"
  end

  test "event lead can review close all confirmation" do
    get close_all_confirmation_event_silent_auction_items_url(@event)

    assert_response :success
    assert_select "h1", "Close All Auction Items"
    assert_select "td", text: "Weekend Getaway"
  end

  test "event lead can review new winner confirmation" do
    item = @event.silent_auction_items.create!(
      name: "Replacement Candidate Item",
      description: "Closed item with replacement candidates.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/replacement-candidate.jpg",
      status: "open"
    )
    replacement_bid = item.silent_auction_bids.create!(
      bidder_name: "Replacement Bidder",
      bidder_phone: "585-555-0180",
      bidder_email: "replacement-bidder@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    current_bid = item.silent_auction_bids.create!(
      bidder_name: "Current Bidder",
      bidder_phone: "585-555-0181",
      bidder_email: "current-bidder@example.com",
      amount_cents: 7500,
      commitment_confirmation: "1",
      minimum_bid_cents: 7500
    )
    item.update!(status: "closed", closed_at: Time.current, winning_bid: current_bid)
    item.create_invoice_record!(
      stripe_invoice_id: "in_current_123",
      stripe_status: "open",
      amount_cents: current_bid.amount_cents,
      customer_name: current_bid.bidder_name,
      customer_email: current_bid.bidder_email,
      due_at: 2.days.from_now
    )

    get promote_winner_confirmation_event_silent_auction_item_url(@event, item, bid_id: replacement_bid.id)

    assert_response :success
    assert_select "h1", "Select New Winner"
    assert_select ".alert", text: /current invoice has not expired/
    assert_select "dd", text: /Replacement Bidder/
    assert_select "form[action='#{promote_winner_event_silent_auction_item_path(@event, item)}']"
  end

  test "paid invoice locks item controls and styles paid status green" do
    item, _replacement_bid = paid_invoice_item

    get event_silent_auction_item_url(@event, item)

    assert_response :success
    assert_select "a", text: "Edit", count: 0
    assert_select "a", text: "Select winner", count: 0
    assert_select ".badge.text-bg-success", text: "paid"
    assert_select ".badge.text-bg-success", text: "Paid invoice locked"
  end

  test "paid invoice status is green on index" do
    paid_invoice_item

    get event_silent_auction_items_url(@event)

    assert_response :success
    assert_select ".badge.text-bg-success", text: "paid"
  end

  test "event lead can retry partial invoice failures" do
    item = @event.silent_auction_items.create!(
      name: "Partial Invoice Item",
      description: "Closed item with a partial invoice.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/partial-invoice-item.jpg",
      status: "open"
    )
    bid = item.silent_auction_bids.create!(
      bidder_name: "Partial Bidder",
      bidder_phone: "585-555-0182",
      bidder_email: "partial-bidder@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    item.update!(status: "closed", closed_at: Time.current, winning_bid: bid)
    item.create_invoice_record!(
      stripe_invoice_id: "in_partial_123",
      stripe_status: "draft",
      amount_cents: bid.amount_cents,
      customer_name: bid.bidder_name,
      customer_email: bid.bidder_email,
      customer_phone: bid.bidder_phone,
      last_error: "invoice item failure"
    )

    get event_silent_auction_item_url(@event, item)

    assert_response :success
    assert_select "dd.text-danger", text: "invoice item failure"
    assert_select "form[action='#{retry_invoice_event_silent_auction_item_path(@event, item)}']"
  end

  test "event lead cannot update item with paid invoice" do
    item, _replacement_bid = paid_invoice_item

    patch event_silent_auction_item_url(@event, item), params: {
      silent_auction_item: {
        name: "Changed Prize",
        description: item.description,
        formatted_starting_bid: "99.00",
        image_url: item.image_url
      }
    }

    assert_redirected_to event_silent_auction_item_url(@event, item)
    assert_equal "Paid invoices cannot be changed.", flash[:alert]
    assert_not_equal "Changed Prize", item.reload.name
  end

  test "event lead cannot review new winner confirmation for paid invoice" do
    item, replacement_bid = paid_invoice_item

    get promote_winner_confirmation_event_silent_auction_item_url(@event, item, bid_id: replacement_bid.id)

    assert_redirected_to event_silent_auction_item_url(@event, item)
    assert_equal "Paid invoices cannot be changed.", flash[:alert]
  end

  test "event lead can close all no-bid items without invoices" do
    empty_event = events(:two)
    first = empty_event.silent_auction_items.create!(
      name: "No Bid One",
      description: "No bid item.",
      starting_bid_cents: 1000,
      image_url: "https://example.com/no-bid-one.jpg",
      status: "open"
    )
    second = empty_event.silent_auction_items.create!(
      name: "No Bid Two",
      description: "No bid item.",
      starting_bid_cents: 2000,
      image_url: "https://example.com/no-bid-two.jpg",
      status: "paused"
    )

    patch close_all_event_silent_auction_items_url(empty_event)

    assert_redirected_to event_silent_auction_items_url(empty_event)
    assert_equal "closed", first.reload.status
    assert_equal "closed", second.reload.status
  end

  test "cashier cannot manage silent auction" do
    sign_in(users(:one))

    get event_silent_auction_items_url(@event)

    assert_redirected_to pos_main_url
  end

  private

  def paid_invoice_item
    item = @event.silent_auction_items.create!(
      name: "Paid Invoice Item",
      description: "Closed item with a paid invoice.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/paid-invoice-item.jpg",
      status: "open"
    )
    replacement_bid = item.silent_auction_bids.create!(
      bidder_name: "Replacement Bidder",
      bidder_phone: "585-555-0180",
      bidder_email: "replacement-bidder@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    current_bid = item.silent_auction_bids.create!(
      bidder_name: "Current Bidder",
      bidder_phone: "585-555-0181",
      bidder_email: "current-bidder@example.com",
      amount_cents: 7500,
      commitment_confirmation: "1",
      minimum_bid_cents: 7500
    )
    item.update!(status: "closed", closed_at: Time.current, winning_bid: current_bid)
    item.create_invoice_record!(
      stripe_invoice_id: "in_paid_123",
      stripe_status: "paid",
      amount_cents: current_bid.amount_cents,
      customer_name: current_bid.bidder_name,
      customer_email: current_bid.bidder_email,
      paid_at: Time.current
    )

    [item, replacement_bid]
  end
end
