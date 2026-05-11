class InvoiceSetting < ApplicationRecord
  before_validation :normalize_stripe_payment_method_configuration_id

  validates :days_until_due, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }
  validates :stripe_payment_method_configuration_id,
            format: { with: /\Apmc_[A-Za-z0-9_]+\z/, message: "must start with pmc_" },
            allow_blank: true

  def self.current
    first_or_create!(days_until_due: 7)
  end

  def stripe_payment_method_configuration_id?
    stripe_payment_method_configuration_id.present?
  end

  private

  def normalize_stripe_payment_method_configuration_id
    self.stripe_payment_method_configuration_id = stripe_payment_method_configuration_id.to_s.strip.presence
  end
end
