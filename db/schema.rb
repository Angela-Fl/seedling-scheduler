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

ActiveRecord::Schema[8.1].define(version: 2025_12_07_003802) do
  create_table "plants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.text "notes"
    t.string "sowing_method"
    t.datetime "updated_at", null: false
    t.string "variety"
    t.integer "weeks_after_last_frost_to_plant"
    t.integer "weeks_before_last_frost_to_start"
    t.integer "weeks_before_last_frost_to_transplant"
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
    t.text "notes"
    t.integer "plant_id", null: false
    t.string "status"
    t.string "task_type"
    t.datetime "updated_at", null: false
    t.index ["plant_id"], name: "index_tasks_on_plant_id"
  end

  add_foreign_key "tasks", "plants"
end
