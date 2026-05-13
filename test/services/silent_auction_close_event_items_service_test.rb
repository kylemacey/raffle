require "test_helper"
require "minitest/mock"
require "ostruct"

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

  test "retries closed items with failed active invoice records" do
    event = events(:two)
    item = event.silent_auction_items.create!(
      name: "Closed Failed Invoice Prize",
      description: "Closed prize with a failed invoice.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/closed-failed-invoice.jpg",
      status: "open"
    )
    bid = item.silent_auction_bids.create!(
      bidder_name: "Retry Winner",
      bidder_phone: "585-555-0103",
      bidder_email: "retry-winner@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    item.update!(status: "closed", closed_at: Time.current, winning_bid: bid)
    invoice_record = item.create_invoice_record!(
      amount_cents: bid.amount_cents,
      customer_name: bid.bidder_name,
      customer_email: bid.bidder_email,
      customer_phone: bid.bidder_phone,
      last_error: "temporary failure"
    )
    customer = OpenStruct.new(id: "cus_retry_event", email: bid.bidder_email, created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs(invoice_id: "in_retry_event_123") do
        result = SilentAuction::CloseEventItemsService.new(event).call

        assert result.success?
      end
    end

    invoice_record.reload
    assert_equal "in_retry_event_123", invoice_record.stripe_invoice_id
    assert_nil invoice_record.last_error
    assert invoice_record.sent_at
  end

  private

  def with_invoice_stubs(invoice_id:)
    invoice = OpenStruct.new(id: invoice_id, status: "draft")
    finalized_invoice = OpenStruct.new(id: invoice_id, status: "open")
    sent_invoice = stripe_invoice(
      id: invoice_id,
      status: "open",
      hosted_invoice_url: "https://invoice.stripe.com/i/retry-event",
      invoice_pdf: "https://pay.stripe.com/invoice/retry-event.pdf"
    )

    Stripe::Invoice.stub(:create, invoice) do
      Stripe::InvoiceItem.stub(:create, OpenStruct.new(id: "ii_retry_event_123")) do
        Stripe::Invoice.stub(:finalize_invoice, finalized_invoice) do
          Stripe::Invoice.stub(:send_invoice, sent_invoice) do
            yield
          end
        end
      end
    end
  end

  def stripe_invoice(id:, status:, hosted_invoice_url:, invoice_pdf:)
    OpenStruct.new(
      id: id,
      status: status,
      hosted_invoice_url: hosted_invoice_url,
      invoice_pdf: invoice_pdf,
      due_date: 1_700_604_800,
      status_transitions: {
        "finalized_at" => 1_700_000_000,
        "paid_at" => nil,
        "voided_at" => nil
      },
      attempt_count: 0
    )
  end
end
