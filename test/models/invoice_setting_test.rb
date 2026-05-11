require "test_helper"

class InvoiceSettingTest < ActiveSupport::TestCase
  test "current returns singleton setting" do
    assert_equal invoice_settings(:default), InvoiceSetting.current
  end

  test "days until due must be positive" do
    setting = InvoiceSetting.new(days_until_due: 0)

    assert_not setting.valid?
  end

  test "payment method configuration id is optional" do
    setting = InvoiceSetting.new(days_until_due: 7, stripe_payment_method_configuration_id: "")

    assert setting.valid?
    assert_nil setting.stripe_payment_method_configuration_id
  end

  test "payment method configuration id must look like a Stripe configuration id" do
    setting = InvoiceSetting.new(days_until_due: 7, stripe_payment_method_configuration_id: "pm_123")

    assert_not setting.valid?
    assert_includes setting.errors[:stripe_payment_method_configuration_id], "must start with pmc_"
  end
end
