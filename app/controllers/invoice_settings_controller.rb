class InvoiceSettingsController < ApplicationController
  before_action -> { require_permission!("invoice_settings.manage") }

  def edit
    @setting = InvoiceSetting.current
  end

  def update
    @setting = InvoiceSetting.current

    if @setting.update(setting_params)
      redirect_to edit_invoice_setting_path, notice: "Invoice settings were updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:invoice_setting).permit(:days_until_due, :stripe_payment_method_configuration_id)
  end
end
