require "test_helper"
require "ostruct"

class InvoiceRecordsCreateOrderFromPaidInvoiceServiceTest < ActiveSupport::TestCase
  test "creates an order for a paid silent auction invoice" do
    item = silent_auction_items(:closed_item)
    invoice_record = item.create_invoice_record!(
      stripe_invoice_id: "in_order_123",
      stripe_status: "paid",
      amount_cents: 7500,
      customer_name: "Auction Winner",
      customer_email: "winner@example.com",
      customer_phone: "(585) 555-0123",
      paid_at: Time.current
    )
    stripe_invoice = OpenStruct.new(id: "in_order_123", payment_intent: "pi_invoice_123")

    assert_difference -> { Order.count }, 1 do
      assert_difference -> { Payment.count }, 1 do
        assert_difference -> { OrderItem.count }, 1 do
          @order = InvoiceRecords::CreateOrderFromPaidInvoiceService.new(invoice_record, stripe_invoice: stripe_invoice).call
        end
      end
    end

    assert_equal @order, invoice_record.reload.order
    assert_equal item.event, @order.event
    assert_equal "Auction Winner", @order.customer_name
    assert_equal "winner@example.com", @order.customer_email
    assert_equal "(585) 555-0123", @order.customer_phone
    assert_equal 7500, @order.total_amount
    assert_equal "stripe_invoice", @order.payment_method_type
    assert @order.user.has_role?("platform_admin")

    order_item = @order.order_items.sole
    assert_equal 1, order_item.quantity
    assert_equal 7500, order_item.unit_price
    assert_equal "Silent Auction: #{item.name}", order_item.pos_product.name
    assert_equal "silent_auction", order_item.pos_product.product_type
    assert_not order_item.pos_product.active?

    payment = @order.payment
    assert_equal "succeeded", payment.status
    assert_equal "stripe_invoice", payment.payment_method_type
    assert_equal "7500", payment.amount
    assert_equal "pi_invoice_123", payment.payment_intent_id
    assert_equal "in_order_123", payment.stripe_invoice_id
  end

  test "is idempotent for duplicate paid invoice events" do
    invoice_record = silent_auction_items(:closed_item).create_invoice_record!(
      stripe_invoice_id: "in_duplicate_123",
      stripe_status: "paid",
      amount_cents: 7500,
      customer_name: "Auction Winner",
      customer_email: "winner@example.com",
      paid_at: Time.current
    )

    first_order = InvoiceRecords::CreateOrderFromPaidInvoiceService.new(invoice_record).call

    assert_no_difference -> { Order.count } do
      assert_no_difference -> { Payment.count } do
        assert_equal first_order, InvoiceRecords::CreateOrderFromPaidInvoiceService.new(invoice_record.reload).call
      end
    end
  end

  test "does not create an order for unpaid invoices" do
    invoice_record = silent_auction_items(:closed_item).create_invoice_record!(
      stripe_invoice_id: "in_unpaid_123",
      stripe_status: "open",
      amount_cents: 7500,
      customer_name: "Auction Winner",
      customer_email: "winner@example.com"
    )

    assert_no_difference -> { Order.count } do
      assert_nil InvoiceRecords::CreateOrderFromPaidInvoiceService.new(invoice_record).call
    end
  end
end
