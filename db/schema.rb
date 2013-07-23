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

ActiveRecord::Schema.define(version: 20130723045001) do

  create_table "activities", force: true do |t|
    t.integer  "family_id"
    t.integer  "user_id"
    t.date     "activity_date"
    t.string   "notes"
    t.string   "reported_by"
    t.boolean  "visit",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "families", force: true do |t|
    t.string   "name"
    t.string   "phone"
    t.string   "email"
    t.string   "address"
    t.string   "children"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "investigator",     default: false
    t.boolean  "watched",          default: false
    t.boolean  "archived",         default: false
    t.boolean  "confirmed_change", default: false
  end

  add_index "families", ["archived"], name: "index_families_on_archived"
  add_index "families", ["investigator"], name: "index_families_on_investigator"
  add_index "families", ["name"], name: "index_families_on_name"

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           default: false
    t.boolean  "active",          default: true
    t.boolean  "master",          default: false
    t.integer  "ward_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["remember_token"], name: "index_users_on_remember_token"

  create_table "wards", force: true do |t|
    t.string   "name"
    t.string   "unit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ward_token"
  end

  add_index "wards", ["name"], name: "index_wards_on_name"
  add_index "wards", ["ward_token"], name: "index_wards_on_ward_token"

end
