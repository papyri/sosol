# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091019182632) do

  create_table "boards", :force => true do |t|
    t.string   "title"
    t.string   "category"
    t.integer  "decree_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "finalizer_user_id"
    t.text     "identifier_classes"
  end

  create_table "boards_users", :id => false, :force => true do |t|
    t.integer  "board_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "boards_users", ["board_id", "user_id"], :name => "index_boards_users_on_board_id_and_user_id", :unique => true

  create_table "decrees", :force => true do |t|
    t.string   "action"
    t.decimal  "trigger"
    t.string   "choices"
    t.integer  "board_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emailers", :force => true do |t|
    t.integer  "board_id"
    t.integer  "user_id"
    t.text     "extra_addresses"
    t.string   "when_to_send"
    t.boolean  "include_document"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "send_to_owner"
  end

  create_table "emailers_users", :id => false, :force => true do |t|
    t.string   "emailer_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emailers_users", ["emailer_id", "user_id"], :name => "index_emailers_users_on_emailer_id_and_user_id", :unique => true

  create_table "events", :force => true do |t|
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "target_id"
    t.string   "target_type"
  end

  create_table "identifiers", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id"
    t.string   "alternate_name"
    t.boolean  "modified",       :default => false
  end

  create_table "publications", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "branch"
    t.string   "status"
    t.integer  "creator_id"
    t.string   "creator_type"
  end

  create_table "user_identifiers", :force => true do |t|
    t.string   "identifier"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "has_repository", :default => false
    t.string   "language_prefs"
    t.boolean  "admin"
    t.boolean  "developer"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "affiliation"
    t.string   "email"
    t.integer  "emailer_id"
  end

  create_table "votes", :force => true do |t|
    t.string   "choice"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id"
  end

end
