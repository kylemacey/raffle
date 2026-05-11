require "test_helper"
require "ostruct"

class InvoiceRecordTest < ActiveSupport::TestCase
  test "syncs status and invoice URLs from stripe invoice" do
    record = silent_auction_items(:closed_item).create_invoice_record!(
      amount_cents: 7500,
      customer_name: "Winner",
      customer_email: "winner@example.com"
    )
    invoice = OpenStruct.new(
      status: "paid",
      hosted_invoice_url: "https://invoice.stripe.com/i/test",
      invoice_pdf: "https://pay.stripe.com/invoice/test.pdf",
      due_date: 1_700_086_400,
      status_transitions: {
        "finalized_at" => 1_700_000_000,
        "paid_at" => 1_700_000_100,
        "voided_at" => nil
      },
      attempt_count: 1
    )

    record.sync_from_stripe_invoice!(invoice)

    assert_equal "paid", record.stripe_status
    assert_equal "https://invoice.stripe.com/i/test", record.stripe_invoice_url
    assert_equal "https://pay.stripe.com/invoice/test.pdf", record.stripe_invoice_pdf
    assert record.paid_at
    assert record.due_at
  end

  test "unexpired is false for superseded invoice records" do
    record = silent_auction_items(:closed_item).create_invoice_record!(
      stripe_status: "open",
      amount_cents: 7500,
      customer_name: "Winner",
      customer_email: "winner@example.com",
      due_at: 2.days.from_now
    )

    assert record.unexpired?

    record.mark_superseded!

    assert record.superseded_at
    assert_not record.unexpired?
  end
end
