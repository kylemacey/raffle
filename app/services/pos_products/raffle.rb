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

    def self.configuration_schema
      [
        {
          name: 'tickets_per_unit',
          type: 'integer',
          label: 'Tickets per unit',
          description: 'Number of raffle tickets created per unit purchased',
          required: true,
          default: 1
        },
        {
          name: 'auto_draw',
          type: 'boolean',
          label: 'Auto-draw enabled',
          description: 'Automatically create drawing entries when tickets are purchased',
          required: false,
          default: false
        }
      ]
    end
  end
end