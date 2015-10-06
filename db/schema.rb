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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150930184341) do

  create_table "boards", :force => true do |t|
    t.string   "title"
    t.string   "category"
    t.integer  "decree_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "finalizer_user_id"
    t.text     "identifier_classes"
    t.decimal  "rank"
    t.string   "friendly_name"
    t.integer  "community_id"
  end

  create_table "boards_users", :id => false, :force => true do |t|
    t.integer  "board_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "boards_users", ["board_id", "user_id"], :name => "index_boards_users_on_board_id_and_user_id", :unique => true

  create_table "comments", :force => true do |t|
    t.text     "comment"
    t.integer  "user_id"
    t.integer  "identifier_id"
    t.string   "reason"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "git_hash"
    t.integer  "publication_id"
  end

  create_table "communities", :force => true do |t|
    t.string   "name"
    t.string   "friendly_name"
    t.integer  "members"
    t.integer  "admins"
    t.string   "description"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "board_id"
    t.integer  "publication_id"
    t.integer  "end_user_id"
    t.boolean  "allows_self_signup", :default => false
    t.boolean  "is_default",         :default => false,              :null => false
    t.string   "type",               :default => "EndUserCommunity", :null => false
  end

  create_table "communities_admins", :id => false, :force => true do |t|
    t.integer  "community_id"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "communities_members", :id => false, :force => true do |t|
    t.integer  "community_id"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "decrees", :force => true do |t|
    t.string   "action"
    t.decimal  "trigger",      :precision => 5, :scale => 2
    t.string   "choices"
    t.integer  "board_id"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "tally_method"
  end

  create_table "docos", :force => true do |t|
    t.decimal  "line",        :precision => 7, :scale => 2
    t.string   "category"
    t.string   "description"
    t.string   "preview"
    t.string   "leiden"
    t.string   "xml"
    t.string   "url"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.string   "urldisplay"
    t.text     "note"
    t.string   "docotype",                                  :default => "text", :null => false
  end

  add_index "docos", ["docotype"], :name => "index_docos_on_docotype"
  add_index "docos", ["id", "docotype"], :name => "index_docos_on_id_and_docotype"

  create_table "emailers", :force => true do |t|
    t.integer  "board_id"
    t.integer  "user_id"
    t.text     "extra_addresses"
    t.string   "when_to_send"
    t.boolean  "include_document"
    t.text     "message"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.boolean  "send_to_owner"
    t.boolean  "send_to_all_board_members", :default => false
    t.boolean  "include_comments",          :default => false
  end

  create_table "emailers_users", :id => false, :force => true do |t|
    t.string   "emailer_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "emailers_users", ["emailer_id", "user_id"], :name => "index_emailers_users_on_emailer_id_and_user_id", :unique => true

  create_table "events", :force => true do |t|
    t.string   "category"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "target_id"
    t.string   "target_type"
  end

  create_table "identifiers", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "publication_id"
    t.string   "alternate_name"
    t.boolean  "modified",       :default => false
    t.string   "title"
    t.string   "status",         :default => "editing"
    t.integer  "board_id"
  end

  create_table "publications", :force => true do |t|
    t.string   "title"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "branch"
    t.string   "status",       :default => "editing"
    t.integer  "creator_id"
    t.string   "creator_type"
    t.integer  "parent_id"
    t.integer  "community_id"
  end

  create_table "user_identifiers", :force => true do |t|
    t.string   "identifier"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.boolean  "has_repository",            :default => false
    t.string   "language_prefs"
    t.boolean  "admin"
    t.boolean  "developer"
    t.string   "affiliation"
    t.string   "email"
    t.integer  "emailer_id"
    t.string   "full_name"
    t.boolean  "is_community_master_admin", :default => false
    t.boolean  "is_master_admin",           :default => false
  end

  create_table "votes", :force => true do |t|
    t.string   "choice"
    t.integer  "user_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "publication_id"
    t.integer  "identifier_id"
    t.integer  "board_id"
  end

end
