# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170211141743) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "machines", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machines_users", id: false, force: :cascade do |t|
    t.integer "machine_id", null: false
    t.integer "user_id",    null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer "fl_id"
    t.integer "member_id"
    t.string  "first_name"
    t.string  "last_name"
    t.string  "display_name"
    t.boolean "active"
    t.string  "card_id"
    t.boolean "can_login"
    t.boolean "can_provision"
    t.boolean "can_deprovision"
    t.string  "name"
  end

end
