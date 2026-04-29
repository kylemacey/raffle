class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string :customer_name
      t.string :customer_email
      t.integer :total_amount
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :payment_method_type

      t.timestamps
    end
  end
end
