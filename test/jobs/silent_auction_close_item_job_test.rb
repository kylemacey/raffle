require "test_helper"
require "minitest/mock"
require "ostruct"

class SilentAuctionCloseItemJobTest < ActiveJob::TestCase
  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "performs invoice creation for a silent auction item" do
    item = build_item_with_bid(email: "job-winner@example.com")
    customer = OpenStruct.new(id: "cus_job", email: "job-winner@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs(invoice_id: "in_job_123") do
        perform_enqueued_jobs do
          SilentAuction::CloseItemJob.perform_later(item)
        end
      end
    end

    assert_equal "closed", item.reload.status
    assert_equal "in_job_123", item.invoice_record.stripe_invoice_id
    assert_nil item.invoice_record.last_error
  end

  test "records retryable invoice failure and can succeed on a later perform" do
    item = build_item_with_bid(email: "job-retry@example.com")
    customer = OpenStruct.new(id: "cus_retry_job", email: "job-retry@example.com", created: 30)

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:create, ->(*) { raise Stripe::APIError.new("temporary failure") }) do
        assert_enqueued_jobs 1, only: SilentAuction::CloseItemJob do
          SilentAuction::CloseItemJob.perform_now(item)
        end
      end
    end

    assert_equal "temporary failure", item.reload.invoice_record.last_error
    clear_enqueued_jobs

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      with_invoice_stubs(invoice_id: "in_retry_job_123") do
        SilentAuction::CloseItemJob.perform_now(item)
      end
    end

    assert_equal "in_retry_job_123", item.reload.invoice_record.stripe_invoice_id
    assert_nil item.invoice_record.last_error
  end

  test "resumes partially created draft invoice without duplicate line items" do
    item = build_item_with_bid(email: "job-partial@example.com")
    winning_bid = item.current_bid
    customer = OpenStruct.new(id: "cus_partial_job", email: "job-partial@example.com", created: 30)
    item.update!(status: "closed", closed_at: Time.current, winning_bid: winning_bid)
    invoice_record = item.create_invoice_record!(
      stripe_invoice_id: "in_partial_job_123",
      stripe_status: "draft",
      amount_cents: winning_bid.amount_cents,
      customer_name: winning_bid.bidder_name,
      customer_email: winning_bid.bidder_email,
      customer_phone: winning_bid.bidder_phone,
      last_error: "invoice item failure"
    )
    existing_line_item = OpenStruct.new(
      amount: winning_bid.amount_cents,
      description: "Silent Auction: #{item.name}",
      metadata: { "silent_auction_item_id" => item.id.to_s }
    )
    retrieved_invoice = OpenStruct.new(
      id: invoice_record.stripe_invoice_id,
      status: "draft",
      lines: OpenStruct.new(data: [existing_line_item])
    )
    finalized_invoice = OpenStruct.new(id: invoice_record.stripe_invoice_id, status: "open")
    sent_invoice = stripe_invoice(
      id: invoice_record.stripe_invoice_id,
      status: "open",
      hosted_invoice_url: "https://invoice.stripe.com/i/partial-job",
      invoice_pdf: "https://pay.stripe.com/invoice/partial-job.pdf"
    )

    Stripe::Customer.stub(:search, OpenStruct.new(data: [customer])) do
      Stripe::Invoice.stub(:retrieve, retrieved_invoice) do
        Stripe::InvoiceItem.stub(:create, ->(*) { raise "should not create duplicate invoice item" }) do
          Stripe::Invoice.stub(:finalize_invoice, finalized_invoice) do
            Stripe::Invoice.stub(:send_invoice, sent_invoice) do
              SilentAuction::CloseItemJob.perform_now(item)
            end
          end
        end
      end
    end

    assert_nil invoice_record.reload.last_error
    assert invoice_record.finalized_at
    assert invoice_record.sent_at
  end

  private

  def build_item_with_bid(email:)
    item = events(:one).silent_auction_items.create!(
      name: "Job Invoice Prize",
      description: "Prize description.",
      starting_bid_cents: 5000,
      image_url: "https://example.com/job-invoice-prize.jpg",
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

  def with_invoice_stubs(invoice_id:)
    invoice = OpenStruct.new(id: invoice_id, status: "draft")
    finalized_invoice = OpenStruct.new(id: invoice_id, status: "open")
    sent_invoice = stripe_invoice(
      id: invoice_id,
      status: "open",
      hosted_invoice_url: "https://invoice.stripe.com/i/job",
      invoice_pdf: "https://pay.stripe.com/invoice/job.pdf"
    )

    Stripe::Invoice.stub(:create, invoice) do
      Stripe::InvoiceItem.stub(:create, OpenStruct.new(id: "ii_job_123")) do
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
