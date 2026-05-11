require "test_helper"

class InvoiceSettingTest < ActiveSupport::TestCase
  test "current returns singleton setting" do
    assert_equal invoice_settings(:default), InvoiceSetting.current
  end

  test "days until due must be positive" do
    setting = InvoiceSetting.new(days_until_due: 0)

    assert_not setting.valid?
  end

  test "new settings default to card and us bank account" do
    setting = InvoiceSetting.new(days_until_due: 7)

    assert_equal %w[card us_bank_account], setting.payment_method_types
  end

  test "payment method types are normalized" do
    setting = InvoiceSetting.new(days_until_due: 7, payment_method_types: [" card ", "", "us_bank_account", "card"])

    assert setting.valid?
    assert_equal %w[card us_bank_account], setting.payment_method_types
  end

  test "payment method types may be cleared to use stripe template default" do
    setting = InvoiceSetting.new(days_until_due: 7, payment_method_types: [""])

    assert setting.valid?
    assert_empty setting.payment_method_types
    assert_equal "Stripe invoice template default", setting.payment_method_types_label
  end

  test "payment method types must be supported by stripe invoices" do
    setting = InvoiceSetting.new(days_until_due: 7, payment_method_types: ["card", "made_up_pay"])

    assert_not setting.valid?
    assert_includes setting.errors[:payment_method_types], "include unsupported types: made_up_pay"
  end
end
