class OrderProcessingService
  attr_reader :order

  def initialize(order)
    @order = order
  end

  # Process all items in the order that have processors
  def process_order
    Rails.logger.info "Processing order ##{order.id} with #{order.order_items.count} items"

    processed_items = []
    failed_items = []

    order.order_items.each do |order_item|
      begin
        process_order_item(order_item)
        processed_items << order_item
        Rails.logger.info "Successfully processed order item #{order_item.id} (#{order_item.pos_product.name})"
      rescue => e
        failed_items << { item: order_item, error: e }
        Rails.logger.error "Failed to process order item #{order_item.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    {
      processed: processed_items,
      failed: failed_items,
      success: failed_items.empty?
    }
  end

  private

  def process_order_item(order_item)
    processor = PosProducts::Factory.create_processor(order_item.pos_product)

    unless processor
      Rails.logger.info "No processor found for product type: #{order_item.pos_product.product_type}"
      return
    end

    Rails.logger.info "Processing #{order_item.quantity}x #{order_item.pos_product.name} (#{order_item.pos_product.product_type})"

    # Let the processor handle all the logic including configuration
    processor.process(order_item)
  end

  # Class method for easy usage
  def self.process_order(order)
    new(order).process_order
  end
end