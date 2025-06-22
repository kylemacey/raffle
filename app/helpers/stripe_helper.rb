module StripeHelper
  def stripe_dashboard_url(object_type, object_id, options = {})
    base_url = "https://dashboard.stripe.com"
    path = case object_type.to_s
           when 'payment', 'payments'
             "/payments/#{object_id}"
           when 'product', 'products'
             "/products/#{object_id}"
           when 'price', 'prices'
             "/products/#{object_id}"
           when 'customer', 'customers'
             "/customers/#{object_id}"
           when 'subscription', 'subscriptions'
             "/subscriptions/#{object_id}"
           when 'invoice', 'invoices'
             "/invoices/#{object_id}"
           when 'terminal_location', 'terminal_locations'
             "/terminal/locations/#{object_id}"
           else
             "/#{object_type}/#{object_id}"
           end

    # Add /test prefix if using test Stripe key
    path = "/test#{path}" if stripe_test_mode?

    url = "#{base_url}#{path}"

    if options[:link_text]
      link_to options[:link_text], url, target: "_blank", class: options[:class]
    else
      url
    end
  end

  def stripe_payment_url(payment_intent_id, options = {})
    stripe_dashboard_url('payment', payment_intent_id, options)
  end

  def stripe_product_url(product_id, options = {})
    stripe_dashboard_url('product', product_id, options)
  end

  def stripe_customer_url(customer_id, options = {})
    stripe_dashboard_url('customer', customer_id, options)
  end

  def stripe_subscription_url(subscription_id, options = {})
    stripe_dashboard_url('subscription', subscription_id, options)
  end

  def stripe_invoice_url(invoice_id, options = {})
    stripe_dashboard_url('invoice', invoice_id, options)
  end

  def stripe_terminal_location_url(location_id = nil, options = {})
    if location_id.present?
      stripe_dashboard_url('terminal_location', location_id, options)
    else
      # Link to the general terminal locations page
      base_url = "https://dashboard.stripe.com"
      path = "/terminal/locations"
      path = "/test#{path}" if stripe_test_mode?
      url = "#{base_url}#{path}"

      if options[:link_text]
        link_to options[:link_text], url, target: "_blank", class: options[:class]
      else
        url
      end
    end
  end

  def order_url(order_id)
    "#{request.base_url}/orders/#{order_id}"
  end

  private

  def stripe_test_mode?
    # Check if Stripe is configured and using a test key
    return true unless defined?(Stripe) && Stripe.api_key.present?

    Stripe.api_key.start_with?('sk_test_')
  end
end