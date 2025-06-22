module PosProducts
  class BaseProcessor
    attr_reader :pos_product

    def initialize(pos_product)
      @pos_product = pos_product
    end

    # Override this method in subclasses to implement product-specific processing
    def process(order_item)
      raise NotImplementedError, "#{self.class} must implement #process"
    end

    # Helper method to get configuration values
    def config
      pos_product.configuration || {}
    end

    # Helper method to get a specific config value with default
    def config_value(key, default = nil)
      config[key.to_s] || default
    end
  end
end