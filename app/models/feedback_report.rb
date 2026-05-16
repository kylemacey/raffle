class FeedbackReport < ApplicationRecord
  REPORT_TYPES = %w[bug feedback help].freeze

  belongs_to :user

  validates :user_name, :report_type, :message, :current_path, presence: true
  validates :role_keys, presence: true
  validates :report_type, inclusion: { in: REPORT_TYPES }
  validates :message, length: { maximum: 5_000 }
  validates :contact_name, :contact_email, length: { maximum: 255 }
  validates :current_path, :referrer, :user_agent, length: { maximum: 2_048 }
  validates :remote_ip, length: { maximum: 255 }

  before_validation :normalize_json_fields

  private

  def normalize_json_fields
    self.role_keys = Array(role_keys).map(&:to_s).reject(&:blank?).uniq
    self.browser_metadata = browser_metadata.to_h if browser_metadata.respond_to?(:to_h)
    self.browser_metadata ||= {}
  end
end
