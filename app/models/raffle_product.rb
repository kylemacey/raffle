class RaffleProduct
  DEFAULT_PRODUCT_CONFIG = [
    {
      name: "Single",
      tickets: 1,
      price: 2_00,
    },
    {
      name: "Armlength",
      tickets: 20,
      price: 20_00,
    },
    {
      name: "Farley-height",
      tickets: 60,
      price: 50_00,
    },
    {
      name: "Breakfast Buffet",
      tickets: 150,
      price: 100_00,
    },
    {
      name: "Daddy Warbucks",
      tickets: 300,
      price: 200_00,
    },
  ]

  attr_reader :name, :tickets, :price

  def self.custom_price(num_tickets)
    price_per_ticket = 0
    DEFAULT_PRODUCT_CONFIG.each do |config|
      break if num_tickets < config[:tickets]
      price_per_ticket = config[:price] / (config[:tickets] * 1.0)
    end

    (num_tickets * price_per_ticket / 100.0).ceil * 100
  end

  def self.all
    @all_products ||= DEFAULT_PRODUCT_CONFIG.map(&method(:new))
  end

  def initialize(attrs = {})
    @name, @tickets, @price = attrs.values_at(:name, :tickets, :price)
  end

  def self.get(num_tickets)
    self.all.detect { |p| p.tickets == num_tickets } || new(
      name: "Custom (#{num_tickets})",
      tickets: num_tickets,
      price: self.custom_price(num_tickets),
    )
  end
end