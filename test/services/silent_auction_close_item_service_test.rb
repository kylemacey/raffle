require "test_helper"
require "minitest/mock"
require "ostruct"

class SilentAuctionCloseItemServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:one)
  end

  test "reuses most recent matching stripe customer by normalized email" do
    item = build_item_with_bid(email: "winner@example.com")
    older_customer = OpenStruct.new(id: "cus_old", email: "winner@example.com", created: 10)
    newer_customer = OpenStruct.new(id: "cus_new", email: "winner@example.com", created: 20)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [older_customer, newer_customer])) do
      Stripe::Customer.stub(:create, ->(*) { raise "should not create duplicate customer" }) do
        with_invoice_stubs do
          result = SilentAuction::CloseItemService.new(item).call

          assert result.success?
        end
      end
    end

    invoice_record = item.reload.invoice_record
    assert_equal "closed", item.status
    assert_equal "cus_new", invoice_record.stripe_customer_id
    assert_equal "in_test_123", invoice_record.stripe_invoice_id
    assert_equal item.current_bid, item.winning_bid
  end

  test "creates stripe customer when email has no match" do
    item = build_item_with_bid(email: "new@example.com")
    created_customer = OpenStruct.new(id: "cus_created", email: "new@example.com", created: 30)
    created_params = nil

    Stripe::Customer.stub(:search, OpenStruct.new(data: [])) do
      Stripe::Customer.stub(:create, ->(params) { created_params = params; created_customer }) do
        with_invoice_stubs do
          result = SilentAuction::CloseItemService.new(item).call

          assert result.success?
        end
      end
    end

    assert_equal "new@example.com", created_params[:email]
    assert_equal "cus_created", item.reload.invoice_record.stripe_customer_id
  end

  test "closes item without invoice when no bids exist" do
    item = @event.silent_auction_items.create!(
      name: "No Bid Item",
      description: "No bids.",
      starting_bid_cents: 2500,
      image_url: "https://example.com/no-bid.jpg",
      status: "open"
    )

    result = SilentAuction::CloseItemService.new(item).call

    assert result.success?
    assert_equal "closed", item.reload.status
    assert_nil item.invoice_record
  end

  test "records stripe creation failure and can retry" do
    item = build_item_with_bid(email: "retry@example.com")
    customer = OpenStruct.new(id: "cus_retry", email: "retry@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:create, ->(*) { raise Stripe::APIError.new("temporary failure") }) do
        result = SilentAuction::CloseItemService.new(item).call

        assert_not result.success?
      end
    end

    assert_equal "temporary failure", item.reload.invoice_record.last_error
    assert_nil item.invoice_record.stripe_invoice_id

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs do
        result = SilentAuction::CloseItemService.new(item).call

        assert result.success?
      end
    end

    assert_equal "in_test_123", item.reload.invoice_record.stripe_invoice_id
    assert_nil item.invoice_record.last_error
  end

  private

  def build_item_with_bid(email:)
    item = @event.silent_auction_items.create!(
      name: "Invoice Prize",
      description: "Prize description.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/invoice-prize.jpg",
      status: "open"
    )
    item.silent_auction_bids.create!(
      bidder_name: "Invoice Winner",
      bidder_phone: "585-555-0103",
      bidder_email: email,
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    item
  end

  def with_invoice_stubs
    invoice_item_params = nil
    invoice = OpenStruct.new(id: "in_test_123", status: "draft")
    finalized_invoice = OpenStruct.new(id: "in_test_123", status: "open")
    sent_invoice = OpenStruct.new(
      id: "in_test_123",
      status: "open",
      hosted_invoice_url: "https://invoice.stripe.com/i/test",
      invoice_pdf: "https://pay.stripe.com/invoice/test.pdf",
      status_transitions: {
        "finalized_at" => 1_700_000_000,
        "paid_at" => nil,
        "voided_at" => nil
      },
      attempt_count: 0
    )

    Stripe::Invoice.stub(:create, invoice) do
      Stripe::InvoiceItem.stub(:create, ->(params) { invoice_item_params = params; OpenStruct.new(id: "ii_test_123") }) do
        Stripe::Invoice.stub(:finalize_invoice, finalized_invoice) do
          Stripe::Invoice.stub(:send_invoice, sent_invoice) do
            yield
          end
        end
      end
    end

    assert_equal 5000, invoice_item_params[:amount]
    assert_equal "usd", invoice_item_params[:currency]
  end
end
