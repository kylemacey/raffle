class Order < ApplicationRecord
  belongs_to :event
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :pos_products, through: :order_items
  has_one :payment, dependent: :destroy

  validates :customer_name, presence: true
  validates :customer_email, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  def process_after_payment
    order_items.each(&:process_after_payment)
  end
end
