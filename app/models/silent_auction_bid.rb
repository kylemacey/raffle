class SilentAuctionBid < ApplicationRecord
  PHONE_ALLOWED_CHARACTERS = /\A[\d()\-\s]+\z/.freeze

  attr_accessor :commitment_confirmation, :minimum_bid_cents

  belongs_to :silent_auction_item

  before_validation :normalize_contact_fields
  before_save :format_phone

  validates :bidder_name, presence: true
  validates :bidder_phone, presence: true
  validates :bidder_email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :commitment_confirmation, acceptance: { accept: "1", allow_nil: false }, on: :create
  validate :phone_contains_allowed_characters
  validate :phone_has_ten_digits
  validate :item_accepts_bids, on: :create
  validate :meets_minimum_bid, on: :create

  def formatted_amount
    (amount_cents / 100.0) if amount_cents.present?
  end

  def formatted_amount=(amount)
    self.amount_cents = SilentAuctionItem.cents_from_amount(amount)
  end

  private

  def normalize_contact_fields
    self.bidder_name = bidder_name.to_s.strip
    self.bidder_phone = bidder_phone.to_s.strip
    self.bidder_email = bidder_email.to_s.strip.downcase
  end

  def phone_contains_allowed_characters
    return if bidder_phone.blank?
    return if bidder_phone.match?(PHONE_ALLOWED_CHARACTERS)

    errors.add(:bidder_phone, "can only include digits, spaces, parentheses, and hyphens")
  end

  def phone_has_ten_digits
    return if bidder_phone.blank?
    return if phone_digits.length == 10

    errors.add(:bidder_phone, "must contain exactly 10 digits")
  end

  def format_phone
    return unless phone_digits.length == 10

    self.bidder_phone = "(#{phone_digits[0, 3]}) #{phone_digits[3, 3]}-#{phone_digits[6, 4]}"
  end

  def phone_digits
    bidder_phone.to_s.scan(/\d/).join
  end

  def item_accepts_bids
    return if silent_auction_item&.open?

    errors.add(:base, "This item is not accepting bids.")
  end

  def meets_minimum_bid
    return if amount_cents.blank? || silent_auction_item.blank?

    minimum = minimum_bid_cents || silent_auction_item.next_minimum_bid_cents
    return if amount_cents >= minimum

    errors.add(:amount_cents, "must be at least #{ActiveSupport::NumberHelper.number_to_currency(minimum / 100.0)}")
  end
end
