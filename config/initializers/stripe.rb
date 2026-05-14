module Raffle
  module StripeConfiguration
    TEST_KEY_PREFIXES = ["sk_test_", "rk_test_"].freeze
    LIVE_KEY_PREFIXES = ["sk_live_", "rk_live_"].freeze

    class StagingStripeKeyError < StandardError; end

    module_function

    def configure!
      Stripe.api_key = api_key_from_environment
      validate_staging_keys!
    end

    def api_key_from_environment
      configured_api_keys["STRIPE_SECRET_KEY"] || configured_api_keys["STRIPE_API_KEY"]
    end

    def test_mode?
      key = Stripe.api_key.presence || api_key_from_environment
      return true if key.blank?

      test_key?(key)
    end

    def test_key?(key)
      key.to_s.start_with?(*TEST_KEY_PREFIXES)
    end

    def live_key?(key)
      key.to_s.start_with?(*LIVE_KEY_PREFIXES)
    end

    def configured_api_keys
      {
        "STRIPE_SECRET_KEY" => ENV["STRIPE_SECRET_KEY"].presence,
        "STRIPE_API_KEY" => ENV["STRIPE_API_KEY"].presence
      }.compact
    end

    def validate_staging_keys!
      return unless Rails.env.staging?

      keys = configured_api_keys
      if keys.empty?
        raise StagingStripeKeyError,
          "RAILS_ENV=staging requires STRIPE_SECRET_KEY or STRIPE_API_KEY set to a Stripe test-mode secret key (sk_test_...) or restricted key (rk_test_...)."
      end

      keys.each do |name, key|
        next if test_key?(key)

        if live_key?(key)
          raise StagingStripeKeyError,
            "RAILS_ENV=staging must use Stripe test-mode credentials; #{name} is a live-mode key."
        end

        raise StagingStripeKeyError,
          "RAILS_ENV=staging requires #{name} to be a Stripe test-mode secret key (sk_test_...) or restricted key (rk_test_...)."
      end
    end
  end
end

Raffle::StripeConfiguration.configure!
