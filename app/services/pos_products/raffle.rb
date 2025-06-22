module PosProducts
  class Raffle < BaseProcessor
    def process(order_item, tickets_to_create:)
      event = order_item.order.event

      Entry.create!(
        name: order_item.order.customer_name,
        phone: order_item.order.customer_email,
        qty: tickets_to_create,
        event: event
      )
    end
  end
end