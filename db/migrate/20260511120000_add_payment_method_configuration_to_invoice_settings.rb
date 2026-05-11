class AddPaymentMethodConfigurationToInvoiceSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :invoice_settings, :stripe_payment_method_configuration_id, :string
  end
end
