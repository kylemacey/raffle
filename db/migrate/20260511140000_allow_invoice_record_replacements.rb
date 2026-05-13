class AllowInvoiceRecordReplacements < ActiveRecord::Migration[7.0]
  def change
    remove_index :invoice_records, name: "index_invoice_records_on_source_type_and_source_id"

    add_column :invoice_records, :due_at, :datetime
    add_column :invoice_records, :superseded_at, :datetime

    add_index :invoice_records,
              [:source_type, :source_id],
              unique: true,
              where: "superseded_at IS NULL",
              name: "index_invoice_records_on_active_source"
    add_index :invoice_records, :superseded_at
  end
end
