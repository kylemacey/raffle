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

  test "passes configured payment method types to stripe invoice create" do
    InvoiceSetting.current.update!(payment_method_types: %w[card us_bank_account])
    item = build_item_with_bid(email: "payment-types@example.com")
    customer = OpenStruct.new(id: "cus_payment_types", email: "payment-types@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs(expected_payment_method_types: %w[card us_bank_account]) do
        result = SilentAuction::CloseItemService.new(item).call

        assert result.success?
      end
    end
  end

  test "omits payment settings when payment method types are cleared" do
    InvoiceSetting.current.update!(payment_method_types: [])
    item = build_item_with_bid(email: "template-default@example.com")
    customer = OpenStruct.new(id: "cus_template_default", email: "template-default@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs(expected_payment_method_types: []) do
        result = SilentAuction::CloseItemService.new(item).call

        assert result.success?
      end
    end
  end

  test "replaces winner by voiding old invoice and sending new invoice" do
    item, replacement_bid, current_bid, old_invoice = build_closed_item_with_two_bids
    customer = OpenStruct.new(id: "cus_replacement", email: replacement_bid.bidder_email, created: 30)
    voided_invoice = stripe_invoice(
      id: old_invoice.stripe_invoice_id,
      status: "void",
      voided_at: 1_700_000_200
    )
    voided_invoice_id = nil

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:void_invoice, ->(invoice_id) { voided_invoice_id = invoice_id; voided_invoice }) do
        with_invoice_stubs(invoice_id: "in_replacement_123") do
          result = SilentAuction::CloseItemService.new(item, winning_bid: replacement_bid, replace_invoice: true).call

          assert result.success?
        end
      end
    end

    assert_equal "in_old_123", voided_invoice_id
    assert_equal replacement_bid, item.reload.winning_bid
    assert_not_equal current_bid, item.winning_bid
    assert old_invoice.reload.superseded_at
    assert_equal "void", old_invoice.stripe_status
    assert_equal "in_replacement_123", item.invoice_record.stripe_invoice_id
    assert_equal replacement_bid.bidder_email, item.invoice_record.customer_email
    assert_equal 2, item.invoice_records.count
  end

  test "replaces winner when old invoice was already voided remotely" do
    item, replacement_bid, _current_bid, old_invoice = build_closed_item_with_two_bids
    customer = OpenStruct.new(id: "cus_replacement", email: replacement_bid.bidder_email, created: 30)
    voided_invoice = stripe_invoice(
      id: old_invoice.stripe_invoice_id,
      status: "void",
      voided_at: 1_700_000_200
    )
    voided_invoice_id = nil
    retrieved_invoice_id = nil

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:void_invoice, ->(invoice_id) {
        voided_invoice_id = invoice_id
        raise Stripe::InvalidRequestError.new("You can only pass in open invoices. This invoice isn't open.", "invoice")
      }) do
        Stripe::Invoice.stub(:retrieve, ->(invoice_id) {
          retrieved_invoice_id = invoice_id
          voided_invoice
        }) do
          with_invoice_stubs(invoice_id: "in_replacement_after_void_123") do
            result = SilentAuction::CloseItemService.new(item, winning_bid: replacement_bid, replace_invoice: true).call

            assert result.success?
          end
        end
      end
    end

    assert_equal "in_old_123", voided_invoice_id
    assert_equal "in_old_123", retrieved_invoice_id
    assert old_invoice.reload.superseded_at
    assert old_invoice.voided_at
    assert_equal replacement_bid, item.reload.winning_bid
    assert_equal "in_replacement_after_void_123", item.invoice_record.stripe_invoice_id
    assert_equal 2, item.invoice_records.count
  end

  test "does not replace winner when remote current invoice has been paid" do
    item, replacement_bid, current_bid, old_invoice = build_closed_item_with_two_bids
    paid_invoice = stripe_invoice(
      id: old_invoice.stripe_invoice_id,
      status: "paid",
      paid_at: 1_700_000_200
    )
    voided_invoice_id = nil
    retrieved_invoice_id = nil

    Stripe::Invoice.stub(:void_invoice, ->(invoice_id) {
      voided_invoice_id = invoice_id
      raise Stripe::InvalidRequestError.new("You can only pass in open invoices. This invoice isn't open.", "invoice")
    }) do
      Stripe::Invoice.stub(:retrieve, ->(invoice_id) {
        retrieved_invoice_id = invoice_id
        paid_invoice
      }) do
        Stripe::Customer.stub(:search, ->(*) { raise "should not create replacement invoice for paid invoice" }) do
          result = SilentAuction::CloseItemService.new(item, winning_bid: replacement_bid, replace_invoice: true).call

          assert_not result.success?
          assert_match "already paid", result.message
        end
      end
    end

    assert_equal "in_old_123", voided_invoice_id
    assert_equal "in_old_123", retrieved_invoice_id
    assert_equal "paid", old_invoice.reload.stripe_status
    assert old_invoice.paid_at
    assert_nil old_invoice.superseded_at
    assert_equal current_bid, item.reload.winning_bid
    assert_equal old_invoice, item.invoice_record
    assert_equal 1, item.invoice_records.count
  end

  test "does not replace winner when current invoice is already paid" do
    item, replacement_bid, current_bid, old_invoice = build_closed_item_with_two_bids
    old_invoice.update!(stripe_status: "paid", paid_at: Time.current)

    result = SilentAuction::CloseItemService.new(item, winning_bid: replacement_bid, replace_invoice: true).call

    assert_not result.success?
    assert_match "already paid", result.message
    assert_equal current_bid, item.reload.winning_bid
    assert_equal old_invoice, item.invoice_record
    assert_not old_invoice.reload.superseded?
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

  def build_closed_item_with_two_bids
    item = @event.silent_auction_items.create!(
      name: "Replacement Prize",
      description: "Prize description.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/replacement-prize.jpg",
      status: "open"
    )
    replacement_bid = item.silent_auction_bids.create!(
      bidder_name: "Replacement Winner",
      bidder_phone: "585-555-0108",
      bidder_email: "replacement@example.com",
      amount_cents: 5000,
      commitment_confirmation: "1",
      minimum_bid_cents: 5000
    )
    current_bid = item.silent_auction_bids.create!(
      bidder_name: "Current Winner",
      bidder_phone: "585-555-0109",
      bidder_email: "current@example.com",
      amount_cents: 7500,
      commitment_confirmation: "1",
      minimum_bid_cents: 7500
    )
    item.update!(
      status: "closed",
      closed_at: Time.current,
      winning_bid: current_bid
    )
    old_invoice = item.create_invoice_record!(
      stripe_invoice_id: "in_old_123",
      stripe_status: "open",
      amount_cents: current_bid.amount_cents,
      customer_name: current_bid.bidder_name,
      customer_email: current_bid.bidder_email,
      customer_phone: current_bid.bidder_phone,
      due_at: 2.days.from_now
    )

    [item, replacement_bid, current_bid, old_invoice]
  end

  def with_invoice_stubs(invoice_id: "in_test_123", expected_payment_method_types: InvoiceSetting.current.payment_method_types)
    invoice_params = nil
    invoice_item_params = nil
    invoice = OpenStruct.new(id: invoice_id, status: "draft")
    finalized_invoice = OpenStruct.new(id: invoice_id, status: "open")
    sent_invoice = stripe_invoice(
      id: invoice_id,
      status: "open",
      hosted_invoice_url: "https://invoice.stripe.com/i/test",
      invoice_pdf: "https://pay.stripe.com/invoice/test.pdf"
    )

    Stripe::Invoice.stub(:create, ->(params) { invoice_params = params; invoice }) do
      Stripe::InvoiceItem.stub(:create, ->(params) { invoice_item_params = params; OpenStruct.new(id: "ii_test_123") }) do
        Stripe::Invoice.stub(:finalize_invoice, finalized_invoice) do
          Stripe::Invoice.stub(:send_invoice, sent_invoice) do
            yield
          end
        end
      end
    end

    assert_equal "send_invoice", invoice_params[:collection_method]
    assert_equal InvoiceSetting.current.days_until_due, invoice_params[:days_until_due]
    if expected_payment_method_types.present?
      assert_equal(
        { payment_method_types: expected_payment_method_types },
        invoice_params[:payment_settings]
      )
    else
      assert_not invoice_params.key?(:payment_settings)
    end
    assert_equal 5000, invoice_item_params[:amount]
    assert_equal "usd", invoice_item_params[:currency]
  end

  def stripe_invoice(id:, status:, hosted_invoice_url: nil, invoice_pdf: nil, finalized_at: 1_700_000_000, paid_at: nil, voided_at: nil)
    OpenStruct.new(
      id: id,
      status: status,
      hosted_invoice_url: hosted_invoice_url,
      invoice_pdf: invoice_pdf,
      due_date: 1_700_604_800,
      status_transitions: {
        "finalized_at" => finalized_at,
        "paid_at" => paid_at,
        "voided_at" => voided_at
      },
      attempt_count: 0
    )
  end
end
