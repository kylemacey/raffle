require "test_helper"

class InvoiceSettingsControllerTest < ActionDispatch::IntegrationTest
  test "admin can update invoice setting" do
    sign_in(users(:admin))

    patch invoice_setting_url, params: {
      invoice_setting: {
        days_until_due: 14
      }
    }

    assert_redirected_to edit_invoice_setting_url
    assert_equal 14, InvoiceSetting.current.reload.days_until_due
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
