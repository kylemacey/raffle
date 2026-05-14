require "test_helper"
require "minitest/mock"

class StripeHelperTest < ActionView::TestCase
  include StripeHelper

  test "dashboard urls include test prefix when Stripe is configured for test mode" do
    Raffle::StripeConfiguration.stub(:test_mode?, true) do
      assert_equal "https://dashboard.stripe.com/test/payments/pi_test_123", stripe_payment_url("pi_test_123")
    end
  end

  test "dashboard urls omit test prefix when Stripe is configured for live mode" do
    Raffle::StripeConfiguration.stub(:test_mode?, false) do
      assert_equal "https://dashboard.stripe.com/payments/pi_live_123", stripe_payment_url("pi_live_123")
    end
  end
end
