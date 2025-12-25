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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_221731) do
  create_table "garden_entries", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.date "entry_date"
    t.datetime "updated_at", null: false
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
    t.string "variety"
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
    t.index ["plant_id"], name: "index_tasks_on_plant_id"
  end

  add_foreign_key "tasks", "plants"
end
