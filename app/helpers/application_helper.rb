module ApplicationHelper
  include StripeHelper

  def container_class
    @full_width_container ? 'container-fluid px-2' : 'container'
  end

  def invoice_status_badge_class(invoice_record)
    return "text-bg-success" if invoice_record.paid?
    return "text-bg-danger" if invoice_record.last_error.present?

    "text-bg-info"
  end

  def invoice_status_label(invoice_record)
    return invoice_record.stripe_status if invoice_record.paid? && invoice_record.stripe_status.present?

    invoice_record.last_error.present? ? "Error" : invoice_record.stripe_status.presence || "Pending"
  end
end
