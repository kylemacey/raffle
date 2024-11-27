module EntriesHelper
  def entry_payment_stripe_url(entry)
    return unless payment = entry&.payment
    return unless payment.payment_method_type == "card"
    if Rails.env.production?
    else
      url = "https://dashboard.stripe.com/test/payments/#{payment.payment_intent_id}"
    end

    link_to payment.payment_intent_id, url, target: :_blank
  end
end
