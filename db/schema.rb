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

ActiveRecord::Schema.define(:version => 20090320151211) do

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
  end

  create_table "boards_users", :id => false, :force => true do |t|
    t.string   "board_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "boards_users", ["board_id", "user_id"], :name => "index_boards_users_on_board_id_and_user_id", :unique => true

  create_table "comments", :force => true do |t|
    t.string   "text"
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

  create_table "events", :force => true do |t|
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "master_articles", :force => true do |t|
    t.integer  "article_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_id"
    t.string   "comment_id"
  end

  create_table "metas", :force => true do |t|
    t.string   "notBeforeDate"
    t.string   "notAfterDate"
    t.string   "onDate"
    t.string   "publication"
    t.string   "language"
    t.string   "subject"
    t.string   "title"
    t.string   "provenance"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.integer  "user_id"
  end

  create_table "transcriptions", :force => true do |t|
    t.string   "content"
    t.string   "leiden"
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translation_contents", :force => true do |t|
    t.string   "content"
    t.integer  "translation_id"
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.string   "epidoc"
    t.string   "language"
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "translation_content_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language_prefs"
  end

  create_table "votes", :force => true do |t|
    t.string   "choice"
    t.string   "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
