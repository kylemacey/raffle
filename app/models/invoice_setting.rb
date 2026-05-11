class InvoiceSetting < ApplicationRecord
  validates :days_until_due, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }

  def self.current
    first_or_create!(days_until_due: 7)
  end
end
