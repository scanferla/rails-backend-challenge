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

ActiveRecord::Schema[8.0].define(version: 2025_09_22_160607) do
  create_table "appointments", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "provider_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["provider_id"], name: "index_appointments_on_provider_id"
    t.check_constraint "ends_at > starts_at", name: "check_appointments_ends_after_starts"
  end

  create_table "availabilities", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.string "source", null: false
    t.string "external_id", null: false
    t.integer "start_day_of_week", null: false
    t.time "start_time", null: false
    t.integer "end_day_of_week", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "source", "external_id"], name: "index_availabilities_on_provider_source_external_id", unique: true
    t.index ["provider_id"], name: "index_availabilities_on_provider_id"
    t.check_constraint "end_day_of_week BETWEEN 0 AND 6", name: "check_availabilities_end_day_of_week_range"
    t.check_constraint "start_day_of_week BETWEEN 0 AND 6", name: "check_availabilities_start_day_of_week_range"
  end

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "appointments", "clients"
  add_foreign_key "appointments", "providers"
  add_foreign_key "availabilities", "providers"
end
