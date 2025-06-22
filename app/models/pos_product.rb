class PosProduct < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stripe_product_id, presence: true

  # JSON configuration for product-specific behavior
  store_accessor :configuration, :processor_service, :processor_config

  scope :active, -> { where(active: true) }

  # Virtual attribute for form display
  def formatted_price
    (price / 100.0) if price.present?
  end

  def formatted_price=(amount)
    if amount.present?
      self.price = (amount.to_s.gsub(/[\$,]/, '').to_f * 100).to_i
    end
  end
end
