require "test_helper"
require "minitest/mock"

class StripeConfigurationTest < ActiveSupport::TestCase
  setup do
    @original_api_key = Stripe.api_key
  end

  teardown do
    Stripe.api_key = @original_api_key
  end

  test "staging accepts test secret keys" do
    with_env("STRIPE_SECRET_KEY" => "sk_test_dummy", "STRIPE_API_KEY" => nil) do
      with_rails_env("staging") do
        Raffle::StripeConfiguration.configure!
      end
    end

    assert_equal "sk_test_dummy", Stripe.api_key
  end

  test "staging accepts test restricted keys" do
    with_env("STRIPE_SECRET_KEY" => nil, "STRIPE_API_KEY" => "rk_test_dummy") do
      with_rails_env("staging") do
        Raffle::StripeConfiguration.configure!
      end
    end

    assert_equal "rk_test_dummy", Stripe.api_key
  end

  test "staging rejects missing keys" do
    error = assert_raises Raffle::StripeConfiguration::StagingStripeKeyError do
      with_env("STRIPE_SECRET_KEY" => nil, "STRIPE_API_KEY" => nil) do
        with_rails_env("staging") do
          Raffle::StripeConfiguration.configure!
        end
      end
    end

    assert_match "RAILS_ENV=staging requires STRIPE_SECRET_KEY or STRIPE_API_KEY", error.message
  end

  test "staging rejects live keys" do
    error = assert_raises Raffle::StripeConfiguration::StagingStripeKeyError do
      with_env("STRIPE_SECRET_KEY" => "sk_live_dummy", "STRIPE_API_KEY" => nil) do
        with_rails_env("staging") do
          Raffle::StripeConfiguration.configure!
        end
      end
    end

    assert_match "STRIPE_SECRET_KEY is a live-mode key", error.message
  end

  test "staging rejects malformed keys" do
    error = assert_raises Raffle::StripeConfiguration::StagingStripeKeyError do
      with_env("STRIPE_SECRET_KEY" => nil, "STRIPE_API_KEY" => "pk_test_dummy") do
        with_rails_env("staging") do
          Raffle::StripeConfiguration.configure!
        end
      end
    end

    assert_match "STRIPE_API_KEY to be a Stripe test-mode secret key", error.message
  end

  test "non staging environments are not blocked by live keys" do
    with_env("STRIPE_SECRET_KEY" => "sk_live_dummy", "STRIPE_API_KEY" => nil) do
      with_rails_env("production") do
        Raffle::StripeConfiguration.configure!
      end
    end

    assert_equal "sk_live_dummy", Stripe.api_key
  end

  private

  def with_rails_env(name)
    Rails.stub(:env, ActiveSupport::StringInquirer.new(name)) do
      yield
    end
  end

  def with_env(values)
    previous_values = values.transform_values { nil }
    values.each do |key, value|
      previous_values[key] = ENV[key]
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    previous_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
