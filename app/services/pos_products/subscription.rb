module PosProducts
  class Subscription < BaseProcessor
    def process(order_item)
      # Subscription processing will be implemented for Roc Stars
      Rails.logger.info "Subscription purchased: #{order_item.order.customer_name} for event #{order_item.order.event.name}"
    end

    def self.configuration_schema
      [
        {
          name: 'subscription_type',
          type: 'select',
          label: 'Subscription Type',
          description: 'Type of subscription to create',
          required: true,
          options: [
            { value: 'monthly', label: 'Monthly' },
            { value: 'yearly', label: 'Yearly' }
          ]
        },
        {
          name: 'auto_renew',
          type: 'boolean',
          label: 'Auto-renew enabled',
          description: 'Automatically renew subscription',
          required: false,
          default: true
        }
      ]
    end
  end
end