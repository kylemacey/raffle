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

ActiveRecord::Schema[7.0].define(version: 2022_06_16_204048) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "drawings", force: :cascade do |t|
    t.string "slug"
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "winners", force: :cascade do |t|
    t.bigint "entry_id", null: false
    t.string "prize"
    t.boolean "present"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "drawing_id", null: false
    t.index ["drawing_id"], name: "index_winners_on_drawing_id"
    t.index ["entry_id"], name: "index_winners_on_entry_id"
  end

  add_foreign_key "drawings", "events"
  add_foreign_key "entries", "events"
  add_foreign_key "winners", "drawings"
  add_foreign_key "winners", "entries"
end
