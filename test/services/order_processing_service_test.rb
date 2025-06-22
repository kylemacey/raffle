require "test_helper"

class OrderProcessingServiceTest < ActiveSupport::TestCase
  def setup
    @event = events(:one)
    @user = users(:one)
    @pos_product = pos_products(:one)

    # Create an order with items
    @order = @event.orders.create!(
      customer_name: "Test Customer",
      customer_email: "test@example.com",
      total_amount: 1000,
      user: @user,
      payment_method_type: "cash"
    )

    @order_item = @order.order_items.create!(
      pos_product: @pos_product,
      quantity: 2,
      unit_price: 500
    )
  end

  test "processes order successfully" do
    result = OrderProcessingService.process_order(@order)

    assert result[:success]
    assert_equal 1, result[:processed].count
    assert_equal 0, result[:failed].count
  end

  test "handles products without processors gracefully" do
    # Create a product without a processor
    @pos_product.update!(product_type: "unknown_type")

    result = OrderProcessingService.process_order(@order)

    assert result[:success]
    assert_equal 1, result[:processed].count
    assert_equal 0, result[:failed].count
  end

  test "processes raffle products with correct ticket count" do
    @pos_product.update!(
      product_type: "raffle",
      configuration: { "tickets_per_unit" => 3 }
    )

    result = OrderProcessingService.process_order(@order)

    assert result[:success]

    # Should create 6 tickets (2 quantity * 3 tickets per unit)
    assert_equal 6, Entry.where(
      name: "Test Customer",
      phone: "test@example.com",
      event: @event
    ).sum(:qty)
  end

  test "handles processing errors gracefully" do
    # Mock the processor to raise an error
    processor = mock
    processor.stubs(:process).raises(StandardError, "Processing failed")

    PosProducts::Factory.stubs(:create_processor).returns(processor)

    result = OrderProcessingService.process_order(@order)

    assert_not result[:success]
    assert_equal 0, result[:processed].count
    assert_equal 1, result[:failed].count
    assert_equal "Processing failed", result[:failed].first[:error].message
  end

  test "class method works correctly" do
    result = OrderProcessingService.process_order(@order)

    assert result[:success]
    assert_equal 1, result[:processed].count
  end

  test "delegates all processing logic to individual processors" do
    # Mock the processor to verify it receives the order_item
    processor = mock
    processor.expects(:process).with(@order_item).once

    PosProducts::Factory.stubs(:create_processor).returns(processor)

    OrderProcessingService.process_order(@order)
  end
end