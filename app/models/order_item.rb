class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :pos_product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }

  def process_after_payment
    processor = PosProducts::Factory.create_processor(pos_product)
    return unless processor

    case pos_product.product_type
    when 'raffle'
      processor.process(self, tickets_to_create: quantity)
    else
      processor.process(self)
    end
  end
end
