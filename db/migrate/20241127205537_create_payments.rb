class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.string :payment_method_type
      t.string :amount
      t.string :payment_intent_id
      t.belongs_to :entry, null: false, foreign_key: true

      t.timestamps
    end
    add_index :payments, :payment_method_type
  end
end
