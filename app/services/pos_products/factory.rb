module PosProducts
  class Factory
    # Map of product types to their processor class names
    PRODUCT_TYPES = {
      'raffle' => 'PosProducts::Raffle',
      'subscription' => 'PosProducts::Subscription'
    }.freeze

    # Get all available product types for forms
    def self.available_types
      PRODUCT_TYPES.keys
    end

    # Get the processor class for a given product type
    def self.processor_for(product_type)
      class_name = PRODUCT_TYPES[product_type]
      return nil unless class_name

      class_name.constantize
    end

    # Create a processor instance for a given product
    def self.create_processor(pos_product)
      processor_class = processor_for(pos_product.product_type)
      return nil unless processor_class

      processor_class.new(pos_product)
    end

    # Check if a product type has a processor
    def self.has_processor?(product_type)
      PRODUCT_TYPES.key?(product_type)
    end

    # Get human-readable names for product types
    def self.human_readable_types
      {
        'raffle' => 'Raffle Tickets',
        'subscription' => 'Subscription'
      }
    end
  end
end