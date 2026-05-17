require "openssl"

class ApiToken < ApplicationRecord
  DEFAULT_EXPIRATION_OPTION = "90_days".freeze
  MAX_GENERATION_ATTEMPTS = 3
  TOKEN_PREFIX_LENGTH = 12
  TOKEN_LAST_FOUR_LENGTH = 4
  TOKEN_RANDOM_BYTES = 32

  EXPIRATION_OPTIONS = {
    "30_days" => "30 days",
    "90_days" => "90 days",
    "1_year" => "1 year",
    "never" => "Never"
  }.freeze

  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true
  validates :token_last_four, presence: true

  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  def self.create_with_generated_token!(attributes)
    api_token = nil
    plain_token = nil

    MAX_GENERATION_ATTEMPTS.times do
      plain_token = generate_token
      api_token = new(attributes.merge(token_attributes(plain_token)))

      return [api_token, plain_token] if api_token.save
      raise ActiveRecord::RecordInvalid, api_token unless retryable_digest_collision?(api_token)
    rescue ActiveRecord::RecordNotUnique
      next
    end

    api_token.save!
    [api_token, plain_token]
  end

  def self.expiration_options
    EXPIRATION_OPTIONS
  end

  def self.expires_at_for(option)
    case option.presence || DEFAULT_EXPIRATION_OPTION
    when "30_days"
      30.days.from_now
    when "90_days"
      90.days.from_now
    when "1_year"
      1.year.from_now
    when "never"
      nil
    else
      expires_at_for(DEFAULT_EXPIRATION_OPTION)
    end
  end

  def self.generate_token
    "raffle_#{SecureRandom.urlsafe_base64(TOKEN_RANDOM_BYTES)}"
  end

  def self.digest_token(token)
    OpenSSL::HMAC.hexdigest("SHA256", hmac_secret, token)
  end

  def self.hmac_secret
    Rails.application.key_generator.generate_key("api-token-digest", 32)
  end

  def self.token_attributes(token)
    {
      token_digest: digest_token(token),
      token_prefix: token.first(TOKEN_PREFIX_LENGTH),
      token_last_four: token.last(TOKEN_LAST_FOUR_LENGTH)
    }
  end

  def self.retryable_digest_collision?(api_token)
    api_token.errors.details.keys == [:token_digest] &&
      api_token.errors.details[:token_digest].any? { |error| error[:error] == :taken }
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def masked_token
    "#{token_prefix}...#{token_last_four}"
  end
end
