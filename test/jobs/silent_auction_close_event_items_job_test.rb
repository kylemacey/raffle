require "test_helper"
require "minitest/mock"
require "ostruct"

class SilentAuctionCloseEventItemsJobTest < ActiveJob::TestCase
  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "closes eligible open and paused items" do
    event = events(:two)
    open_item = event.silent_auction_items.create!(
      name: "Open Job Prize",
      description: "Open prize.",
      starting_bid_cents: 1000,
      image_url: "https://example.com/open-job.jpg",
      status: "open"
    )
    paused_item = event.silent_auction_items.create!(
      name: "Paused Job Prize",
      description: "Paused prize.",
      starting_bid_cents: 2000,
      image_url: "https://example.com/paused-job.jpg",
      status: "paused"
    )
    draft_item = event.silent_auction_items.create!(
      name: "Draft Job Prize",
      description: "Draft prize.",
      starting_bid_cents: 3000,
      image_url: "https://example.com/draft-job.jpg"
    )

    SilentAuction::CloseEventItemsJob.perform_now(event)

    assert_equal "closed", open_item.reload.status
    assert_equal "closed", paused_item.reload.status
    assert_equal "draft", draft_item.reload.status
  end

  test "retries close all when an item has a retryable invoice failure" do
    event = events(:two)
    item = event.silent_auction_items.create!(
      name: "Retryable Event Prize",
      description: "Prize description.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/retryable-event-prize.jpg",
      status: "open"
    )
    item.silent_auction_bids.create!(
      bidder_name: "Retryable Winner",
      bidder_phone: "585-555-0103",
      bidder_email: "retryable-event@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    customer = OpenStruct.new(id: "cus_retryable_event", email: "retryable-event@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:create, ->(*) { raise Stripe::APIError.new("temporary failure") }) do
        assert_enqueued_jobs 1, only: SilentAuction::CloseEventItemsJob do
          SilentAuction::CloseEventItemsJob.perform_now(event)
        end
      end
    end

    assert_equal "temporary failure", item.reload.invoice_record.last_error
  end
end
