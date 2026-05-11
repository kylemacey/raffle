require "test_helper"

class InvoiceSettingsControllerTest < ActionDispatch::IntegrationTest
  test "admin can update invoice setting" do
    sign_in(users(:admin))

    patch invoice_setting_url, params: {
      invoice_setting: {
        days_until_due: 14,
        stripe_payment_method_configuration_id: " pmc_test_123 "
      }
    }

    assert_redirected_to edit_invoice_setting_url
    setting = InvoiceSetting.current.reload
    assert_equal 14, setting.days_until_due
    assert_equal "pmc_test_123", setting.stripe_payment_method_configuration_id
  end

  test "event lead cannot update invoice setting" do
    sign_in(users(:two))

    patch invoice_setting_url, params: {
      invoice_setting: {
        days_until_due: 14
      }
    }

    assert_redirected_to pos_main_url
  end
end
