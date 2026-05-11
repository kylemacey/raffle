# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_05_11_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "drawings", force: :cascade do |t|
    t.string "slug"
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "prize_number_index"
    t.index ["event_id"], name: "index_drawings_on_event_id"
    t.index ["slug"], name: "index_drawings_on_slug"
  end

  create_table "entries", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.integer "qty"
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_entries_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_records", force: :cascade do |t|
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "stripe_invoice_id"
    t.string "stripe_status"
    t.string "stripe_invoice_url"
    t.string "stripe_invoice_pdf"
    t.string "stripe_customer_id"
    t.integer "amount_cents", null: false
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.string "customer_phone"
    t.text "last_error"
    t.datetime "finalized_at"
    t.datetime "sent_at"
    t.datetime "paid_at"
    t.datetime "failed_at"
    t.datetime "voided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "due_at"
    t.datetime "superseded_at"
    t.bigint "order_id"
    t.index ["order_id"], name: "index_invoice_records_on_order_id", unique: true
    t.index ["source_type", "source_id"], name: "index_invoice_records_on_active_source", unique: true, where: "(superseded_at IS NULL)"
    t.index ["stripe_invoice_id"], name: "index_invoice_records_on_stripe_invoice_id", unique: true
    t.index ["stripe_status"], name: "index_invoice_records_on_stripe_status"
    t.index ["superseded_at"], name: "index_invoice_records_on_superseded_at"
  end

  create_table "invoice_settings", force: :cascade do |t|
    t.integer "days_until_due", default: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method_types", default: ["card", "us_bank_account"], null: false, array: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "pos_product_id", null: false
    t.integer "quantity"
    t.integer "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["pos_product_id"], name: "index_order_items_on_pos_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "customer_name"
    t.string "customer_email"
    t.string "customer_phone"
    t.integer "total_amount"
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.string "payment_method_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_orders_on_event_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "payment_method_type"
    t.string "amount"
    t.string "payment_intent_id"
    t.bigint "entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.string "stripe_setup_intent_id"
    t.string "stripe_subscription_id"
    t.string "status"
    t.string "stripe_invoice_id"
    t.index ["entry_id"], name: "index_payments_on_entry_id"
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_method_type"], name: "index_payments_on_payment_method_type"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["stripe_invoice_id"], name: "index_payments_on_stripe_invoice_id", unique: true
    t.index ["stripe_setup_intent_id"], name: "index_payments_on_stripe_setup_intent_id"
    t.index ["stripe_subscription_id"], name: "index_payments_on_stripe_subscription_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_permissions_on_category"
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "pos_products", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.string "stripe_product_id"
    t.string "stripe_price_id"
    t.string "product_type"
    t.boolean "active"
    t.jsonb "configuration"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority"
  end

  create_table "roc_star_prices", force: :cascade do |t|
    t.string "name"
    t.string "stripe_product_id"
    t.integer "amount"
    t.string "interval"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_price_id"
    t.index ["stripe_price_id"], name: "index_roc_star_prices_on_stripe_price_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "system", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "silent_auction_bids", force: :cascade do |t|
    t.bigint "silent_auction_item_id", null: false
    t.string "bidder_name", null: false
    t.string "bidder_phone", null: false
    t.string "bidder_email", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bidder_email"], name: "index_silent_auction_bids_on_bidder_email"
    t.index ["silent_auction_item_id", "amount_cents"], name: "index_silent_auction_bids_on_item_and_amount"
    t.index ["silent_auction_item_id"], name: "index_silent_auction_bids_on_silent_auction_item_id"
  end

  create_table "silent_auction_items", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "starting_bid_cents", default: 0, null: false
    t.string "image_url", null: false
    t.string "status", default: "draft", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "winning_bid_id"
    t.index ["event_id", "status"], name: "index_silent_auction_items_on_event_id_and_status"
    t.index ["event_id"], name: "index_silent_auction_items_on_event_id"
    t.index ["winning_bid_id"], name: "index_silent_auction_items_on_winning_bid_id"
  end

  create_table "silent_auction_settings", force: :cascade do |t|
    t.integer "bid_increment_cents", default: 2500, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "pin"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "winners", force: :cascade do |t|
    t.bigint "entry_id", null: false
    t.string "prize"
    t.boolean "present"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "drawing_id", null: false
    t.string "prize_number"
    t.boolean "claimed"
    t.index ["drawing_id"], name: "index_winners_on_drawing_id"
    t.index ["entry_id"], name: "index_winners_on_entry_id"
  end

  add_foreign_key "drawings", "events"
  add_foreign_key "entries", "events"
  add_foreign_key "invoice_records", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "pos_products"
  add_foreign_key "orders", "events"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "entries"
  add_foreign_key "payments", "orders"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "silent_auction_bids", "silent_auction_items"
  add_foreign_key "silent_auction_items", "events"
  add_foreign_key "silent_auction_items", "silent_auction_bids", column: "winning_bid_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "winners", "drawings"
  add_foreign_key "winners", "entries"
end
