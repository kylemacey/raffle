class StripeWebhookEventJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::Deadlocked,
           ActiveRecord::LockWaitTimeout,
           Stripe::APIConnectionError,
           Stripe::APIError,
           Stripe::RateLimitError,
           wait: 30.seconds,
           attempts: 5

  def perform(event)
    StripeWebhooks::EventProcessor.new(event).call
  end
end
