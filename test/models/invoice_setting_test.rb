require "test_helper"

class InvoiceSettingTest < ActiveSupport::TestCase
  test "current returns singleton setting" do
    assert_equal invoice_settings(:default), InvoiceSetting.current
  end

  test "days until due must be positive" do
    setting = InvoiceSetting.new(days_until_due: 0)

    assert_not setting.valid?
  end
end
