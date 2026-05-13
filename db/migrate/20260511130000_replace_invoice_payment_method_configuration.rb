class ReplaceInvoicePaymentMethodConfiguration < ActiveRecord::Migration[7.0]
  def change
    remove_column :invoice_settings, :stripe_payment_method_configuration_id, :string
    add_column :invoice_settings, :payment_method_types, :string, array: true, default: %w[card us_bank_account], null: false
  end
end
