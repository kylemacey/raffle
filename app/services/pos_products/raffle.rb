module PosProducts
  class Raffle < BaseProcessor
    def process(order_item)
      event = order_item.order.event

      # Calculate tickets to create based on configuration
      tickets_per_unit = config_value('tickets_per_unit', 1).to_i
      tickets_to_create = order_item.quantity * tickets_per_unit

      # Create the entry
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
        }
      ]
    end
  end
end