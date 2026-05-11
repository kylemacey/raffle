class InvoiceRecord < ApplicationRecord
  belongs_to :source, polymorphic: true

  scope :active, -> { where(superseded_at: nil) }
  scope :superseded, -> { where.not(superseded_at: nil) }
  scope :latest_first, -> { order(created_at: :desc) }

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :customer_name, presence: true
  validates :customer_email, presence: true, format: URI::MailTo::EMAIL_REGEXP

  def sync_from_stripe_invoice!(invoice)
    transitions = stripe_value(invoice, :status_transitions) || {}

    update!(
      stripe_status: stripe_value(invoice, :status),
      stripe_invoice_url: stripe_value(invoice, :hosted_invoice_url),
      stripe_invoice_pdf: stripe_value(invoice, :invoice_pdf),
      finalized_at: timestamp_from(transitions, :finalized_at),
      due_at: timestamp_from(invoice, :due_date) || due_at,
      paid_at: timestamp_from(transitions, :paid_at),
      voided_at: timestamp_from(transitions, :voided_at),
      failed_at: failed_timestamp(invoice)
    )
  end

  def superseded?
    superseded_at.present?
  end

  def paid?
    stripe_status == "paid" || paid_at.present?
  end

  def voided?
    stripe_status == "void" || voided_at.present?
  end

  def unexpired?
    due_at.present? && due_at.future? && !paid? && !voided? && !superseded?
  end

  def voidable?
    stripe_invoice_id.present? && !paid? && !voided?
  end

  def supersede!
    update!(superseded_at: Time.current)
  end

  private

  def failed_timestamp(invoice)
    status = stripe_value(invoice, :status)
    return failed_at unless status == "open" && stripe_value(invoice, :attempt_count).to_i.positive?

    Time.current
  end

  def timestamp_from(object, key)
    value = stripe_value(object, key)
    return if value.blank?

    Time.zone.at(value.to_i)
  end

  def stripe_value(object, key)
    if object.respond_to?(key)
      object.public_send(key)
    elsif object.respond_to?(:[])
      object[key.to_s] || object[key]
    end
  end
end
