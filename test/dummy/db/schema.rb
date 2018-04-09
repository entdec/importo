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

ActiveRecord::Schema.define(version: 20180309202732) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scribo_contents", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "scribo_site_id"
    t.string "kind"
    t.string "path"
    t.string "content_type"
    t.string "filter"
    t.string "identifier"
    t.string "name"
    t.string "title"
    t.string "caption"
    t.string "breadcrumb"
    t.string "keywords"
    t.string "description"
    t.string "state"
    t.binary "data"
    t.jsonb "properties"
    t.uuid "layout_id"
    t.uuid "parent_id"
    t.datetime "published_at", default: -> { "timezone('UTC'::text, CURRENT_TIMESTAMP)" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["layout_id"], name: "index_scribo_contents_on_layout_id"
    t.index ["parent_id", "name"], name: "index_scribo_contents_on_parent_id_and_name", unique: true
    t.index ["parent_id"], name: "index_scribo_contents_on_parent_id"
    t.index ["scribo_site_id", "identifier"], name: "index_scribo_contents_identifier", unique: true
    t.index ["scribo_site_id", "path"], name: "index_scribo_contents_path", unique: true
    t.index ["scribo_site_id"], name: "index_scribo_contents_on_scribo_site_id"
  end

  create_table "scribo_sites", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "scribable_type"
    t.uuid "scribable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "host_name", default: ".*"
    t.index ["scribable_type", "scribable_id"], name: "index_scribo_sites_on_scribable_type_and_scribable_id"
  end

  add_foreign_key "scribo_contents", "scribo_contents", column: "layout_id"
  add_foreign_key "scribo_contents", "scribo_contents", column: "parent_id"
  add_foreign_key "scribo_contents", "scribo_sites"
end
