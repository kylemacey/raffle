class AddTerminalSubscriptionTrackingToPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :payments, :stripe_setup_intent_id, :string
    add_column :payments, :stripe_subscription_id, :string
    add_column :payments, :status, :string

    add_index :payments, :stripe_setup_intent_id
    add_index :payments, :stripe_subscription_id
    add_index :payments, :status
  end
end
