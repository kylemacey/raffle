class InvoiceSetting < ApplicationRecord
  PAYMENT_METHOD_TYPE_LABELS = {
    "card" => "Card",
    "us_bank_account" => "ACH direct debit",
    "ach_debit" => "ACH",
    "affirm" => "Affirm",
    "amazon_pay" => "Amazon Pay",
    "cashapp" => "Cash App Pay",
    "customer_balance" => "Bank transfer",
    "link" => "Link",
    "paypal" => "PayPal",
    "klarna" => "Klarna",
    "crypto" => "Crypto",
    "custom" => "Custom",
    "acss_debit" => "Canadian pre-authorized debit",
    "au_becs_debit" => "BECS Direct Debit",
    "bacs_debit" => "Bacs Direct Debit",
    "bancontact" => "Bancontact",
    "boleto" => "Boleto",
    "eps" => "EPS",
    "fpx" => "FPX",
    "giropay" => "giropay",
    "grabpay" => "GrabPay",
    "ideal" => "iDEAL",
    "kakao_pay" => "Kakao Pay",
    "konbini" => "Konbini",
    "kr_card" => "Korean card",
    "multibanco" => "Multibanco",
    "naver_pay" => "Naver Pay",
    "nz_bank_account" => "NZ BECS Direct Debit",
    "p24" => "Przelewy24",
    "pay_by_bank" => "Pay By Bank",
    "payco" => "PAYCO",
    "paynow" => "PayNow",
    "payto" => "PayTo",
    "pix" => "Pix",
    "promptpay" => "PromptPay",
    "revolut_pay" => "Revolut Pay",
    "sepa_debit" => "SEPA Direct Debit",
    "sofort" => "SOFORT",
    "twint" => "TWINT",
    "upi" => "UPI",
    "wechat_pay" => "WeChat Pay"
  }.freeze

  DEFAULT_PAYMENT_METHOD_TYPES = %w[card us_bank_account].freeze

  after_initialize :set_default_payment_method_types, if: :new_record?
  before_validation :normalize_payment_method_types

  validates :days_until_due, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }
  validate :payment_method_types_are_supported

  def self.current
    first_or_create!(days_until_due: 7)
  end

  def self.payment_method_type_options
    PAYMENT_METHOD_TYPE_LABELS.map { |value, label| [label, value] }
  end

  def payment_method_types?
    payment_method_types.present?
  end

  def payment_method_types_label
    return "Stripe invoice template default" if payment_method_types.blank?

    payment_method_types.map { |type| self.class.payment_method_type_label(type) }.join(", ")
  end

  def self.payment_method_type_label(type)
    PAYMENT_METHOD_TYPE_LABELS.fetch(type, type)
  end

  private

  def set_default_payment_method_types
    self.payment_method_types = DEFAULT_PAYMENT_METHOD_TYPES if payment_method_types.blank?
  end

  def normalize_payment_method_types
    self.payment_method_types = Array(payment_method_types).map { |type| type.to_s.strip }.reject(&:blank?).uniq
  end

  def payment_method_types_are_supported
    unsupported_types = Array(payment_method_types) - PAYMENT_METHOD_TYPE_LABELS.keys
    return if unsupported_types.empty?

    errors.add(:payment_method_types, "include unsupported types: #{unsupported_types.join(', ')}")
  end
end
