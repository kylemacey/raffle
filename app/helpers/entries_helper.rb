module EntriesHelper
  def entry_payment_stripe_url(entry)
    return unless payment = entry&.payment
    return unless payment.payment_method_type == "card"
    return unless current_user_can_any?("reports.view_fundraising", "refunds.issue")

    stripe_payment_url(payment.payment_intent_id, link_text: payment.payment_intent_id)
  end
end
