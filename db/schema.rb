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

ActiveRecord::Schema[8.1].define(version: 2026_01_05_055511) do
  create_table "feedback_submissions", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message", null: false
    t.string "page"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_feedback_submissions_on_created_at"
    t.index ["status"], name: "index_feedback_submissions_on_status"
    t.index ["user_id"], name: "index_feedback_submissions_on_user_id"
  end

  create_table "garden_entries", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.date "entry_date"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_garden_entries_on_user_id"
  end

  create_table "plants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "days_to_sprout"
    t.integer "hardening_offset_days"
    t.string "name"
    t.text "notes"
    t.integer "plant_seedlings_offset_days"
    t.integer "plant_seeds_offset_days"
    t.string "plant_spacing"
    t.string "seed_depth"
    t.string "sowing_method"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "variety"
    t.index ["user_id"], name: "index_plants_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "due_date"
    t.date "end_date"
    t.text "notes"
    t.integer "plant_id"
    t.string "status"
    t.string "task_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["plant_id"], name: "index_tasks_on_plant_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "feedback_submissions", "users"
  add_foreign_key "garden_entries", "users"
  add_foreign_key "plants", "users"
  add_foreign_key "tasks", "plants"
  add_foreign_key "tasks", "users"
end
