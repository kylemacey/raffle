class SilentAuctionSetting < ApplicationRecord
  validates :bid_increment_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def self.current
    first_or_create!(bid_increment_cents: 2500)
  end

  def formatted_bid_increment
    (bid_increment_cents / 100.0) if bid_increment_cents.present?
  end

  def formatted_bid_increment=(amount)
    self.bid_increment_cents = SilentAuctionItem.cents_from_amount(amount)
  end
end
