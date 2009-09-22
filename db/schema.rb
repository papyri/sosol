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

ActiveRecord::Schema.define(:version => 20090916153409) do

# Could not dump table "boards" because of following StandardError
#   Unknown type '' for column 'id'

  create_table "boards_users", :id => false, :force => true do |t|
    t.integer  "board_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.string   "extra_addresses"
    t.string   "when_to_send"
    t.boolean  "include_document"
    t.string   "message"
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

# Could not dump table "users" because of following StandardError
#   Unknown type '' for column 'id'

  create_table "votes", :force => true do |t|
    t.string   "choice"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id"
  end

end
