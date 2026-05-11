class LinkInvoiceRecordsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :invoice_records, :order, foreign_key: true, index: { unique: true }

    add_column :payments, :stripe_invoice_id, :string
    add_index :payments, :stripe_invoice_id, unique: true
  end
end
