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

ActiveRecord::Schema.define(:version => 20090929170138) do

  create_table "articles", :force => true do |t|
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "leiden"
    t.integer  "user_id"
    t.string   "pn"
    t.string   "category"
    t.integer  "master_article_id"
    t.integer  "meta_id"
    t.integer  "transcription_id"
    t.integer  "translation_id"
    t.string   "status"
    t.integer  "board_id"
    t.integer  "vote_id"
  end

  create_table "boards", :force => true do |t|
    t.string   "title"
    t.string   "category"
    t.integer  "decree_id"
    t.integer  "article_id"
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

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "reason"
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
    t.text     "extra_addresses"
    t.string   "when"
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

  create_table "glossaries", :force => true do |t|
    t.string   "item"
    t.string   "term"
    t.string   "en"
    t.string   "de"
    t.string   "fr"
    t.string   "sp"
    t.string   "la"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identifiers", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id"
    t.string   "alternate_name"
    t.boolean  "modified",       :default => false
    t.string   "title"
  end

  create_table "master_articles", :force => true do |t|
    t.integer  "article_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "comment_id"
  end

  create_table "metas", :force => true do |t|
    t.string   "notBeforeDate"
    t.string   "notAfterDate"
    t.string   "onDate"
    t.string   "publication"
    t.string   "title"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.integer  "user_id"
    t.string   "material"
    t.string   "bl"
    t.string   "tm_nr"
    t.string   "content"
    t.string   "provenance_ancient_findspot"
    t.string   "provenance_nome"
    t.string   "provenance_ancient_region"
    t.string   "other_publications"
    t.string   "translations"
    t.string   "illustrations"
    t.string   "mentioned_dates"
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

  create_table "transcriptions", :force => true do |t|
    t.text     "content"
    t.text     "leiden"
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translation_contents", :force => true do |t|
    t.text     "content"
    t.integer  "translation_id"
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.text     "epidoc"
    t.string   "language"
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "translation_content_id"
    t.boolean  "xml_to_translations_ok"
    t.boolean  "translations_to_xml_ok"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language_prefs"
    t.boolean  "admin"
    t.boolean  "developer"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "affiliation"
    t.string   "email"
    t.integer  "emailer_id"
    t.boolean  "has_repository", :default => false
  end

  create_table "votes", :force => true do |t|
    t.string   "choice"
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id"
  end

end
