module PosProducts
  class Subscription < BaseProcessor
    def process(order_item)
      # Subscription processing will be implemented for Roc Stars
      Rails.logger.info "Subscription purchased: #{order_item.order.customer_name} for event #{order_item.order.event.name}"
    end
  end
end