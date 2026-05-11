class SilentAuctionItem < ApplicationRecord
  STATUSES = %w[draft paused open closed].freeze
  PUBLIC_STATUSES = %w[paused open closed].freeze

  belongs_to :event
  belongs_to :winning_bid, class_name: "SilentAuctionBid", optional: true
  has_many :silent_auction_bids, dependent: :destroy
  has_one :invoice_record, as: :source, dependent: :destroy

  before_validation :set_default_status

  validates :name, presence: true
  validates :description, presence: true
  validates :image_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :starting_bid_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :publicly_listed, -> { where(status: PUBLIC_STATUSES) }
  scope :ordered_for_admin, -> { order(created_at: :desc) }
  scope :ordered_for_public, -> {
    order(Arel.sql("CASE status WHEN 'open' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END"), created_at: :desc)
  }

  def formatted_starting_bid
    (starting_bid_cents / 100.0) if starting_bid_cents.present?
  end

  def formatted_starting_bid=(amount)
    self.starting_bid_cents = self.class.cents_from_amount(amount)
  end

  def current_bid
    silent_auction_bids.order(amount_cents: :desc, created_at: :asc).first
  end

  def current_bid_cents
    current_bid&.amount_cents || starting_bid_cents
  end

  def bid_count
    if association(:silent_auction_bids).loaded?
      silent_auction_bids.count(&:persisted?)
    else
      silent_auction_bids.count
    end
  end

  def current_bid_label
    current_bid ? "Current bid" : "Starting bid"
  end

  def next_minimum_bid_cents
    return starting_bid_cents unless current_bid

    current_bid.amount_cents + SilentAuctionSetting.current.bid_increment_cents
  end

  def publicly_listed?
    PUBLIC_STATUSES.include?(status)
  end

  def open?
    status == "open"
  end

  def draft?
    status == "draft"
  end

  def paused?
    status == "paused"
  end

  def closed?
    status == "closed"
  end

  def status_label
    status.to_s.titleize
  end

  def self.cents_from_amount(amount)
    return if amount.blank?

    (BigDecimal(amount.to_s.gsub(/[$,]/, "")) * 100).round.to_i
  rescue ArgumentError
    nil
  end

  private

  def set_default_status
    self.status = "draft" if status.blank?
  end
end
