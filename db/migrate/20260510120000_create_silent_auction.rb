class CreateSilentAuction < ActiveRecord::Migration[7.0]
  def change
    create_table :silent_auction_items do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :starting_bid_cents, null: false, default: 0
      t.string :image_url, null: false
      t.string :status, null: false, default: "paused"
      t.datetime :closed_at

      t.timestamps
    end
    add_index :silent_auction_items, [:event_id, :status]

    create_table :silent_auction_bids do |t|
      t.references :silent_auction_item, null: false, foreign_key: true
      t.string :bidder_name, null: false
      t.string :bidder_phone, null: false
      t.string :bidder_email, null: false
      t.integer :amount_cents, null: false

      t.timestamps
    end
    add_index :silent_auction_bids,
              [:silent_auction_item_id, :amount_cents],
              name: "index_silent_auction_bids_on_item_and_amount"
    add_index :silent_auction_bids, :bidder_email

    add_reference :silent_auction_items,
                  :winning_bid,
                  foreign_key: { to_table: :silent_auction_bids, on_delete: :nullify },
                  index: true

    create_table :silent_auction_settings do |t|
      t.integer :bid_increment_cents, null: false, default: 2500

      t.timestamps
    end

    create_table :invoice_settings do |t|
      t.integer :days_until_due, null: false, default: 7

      t.timestamps
    end

    create_table :invoice_records do |t|
      t.references :source, null: false, polymorphic: true, index: false
      t.string :stripe_invoice_id
      t.string :stripe_status
      t.string :stripe_invoice_url
      t.string :stripe_invoice_pdf
      t.string :stripe_customer_id
      t.integer :amount_cents, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone
      t.text :last_error
      t.datetime :finalized_at
      t.datetime :sent_at
      t.datetime :paid_at
      t.datetime :failed_at
      t.datetime :voided_at

      t.timestamps
    end
    add_index :invoice_records, [:source_type, :source_id], unique: true
    add_index :invoice_records, :stripe_invoice_id, unique: true
    add_index :invoice_records, :stripe_status
  end
end
