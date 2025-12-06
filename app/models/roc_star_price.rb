class RocStarPrice < ApplicationRecord
  validates :name, presence: true
  validates :stripe_product_id, presence: true
  validates :stripe_price_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :interval, presence: true, inclusion: { in: %w[month year] }
end
