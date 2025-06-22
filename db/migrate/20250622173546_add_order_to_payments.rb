class AddOrderToPayments < ActiveRecord::Migration[7.0]
  def change
    add_reference :payments, :order, null: true, foreign_key: true
    change_column_null :payments, :entry_id, true
  end
end
