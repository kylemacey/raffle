require "test_helper"

class InvoiceSettingsControllerTest < ActionDispatch::IntegrationTest
  test "admin can update invoice setting" do
    sign_in(users(:admin))

    patch invoice_setting_url, params: {
      invoice_setting: {
        days_until_due: 14,
        payment_method_types: ["card", "us_bank_account", ""]
      }
    }

    assert_redirected_to edit_invoice_setting_url
    setting = InvoiceSetting.current.reload
    assert_equal 14, setting.days_until_due
    assert_equal %w[card us_bank_account], setting.payment_method_types
  end

  test "admin can clear invoice payment method types" do
    sign_in(users(:admin))

    patch invoice_setting_url, params: {
      invoice_setting: {
        days_until_due: 14,
        payment_method_types: [""]
      }
    }

    assert_redirected_to edit_invoice_setting_url
    assert_empty InvoiceSetting.current.reload.payment_method_types
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
