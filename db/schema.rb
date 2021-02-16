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

ActiveRecord::Schema.define(version: 2021_10_04_142258) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "boards", force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.integer "decree_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "finalizer_user_id"
    t.text "identifier_classes"
    t.decimal "rank"
    t.string "friendly_name"
    t.integer "community_id"
  end

  create_table "boards_users", id: false, force: :cascade do |t|
    t.integer "board_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["board_id", "user_id"], name: "index_boards_users_on_board_id_and_user_id", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "comment"
    t.integer "user_id"
    t.integer "identifier_id"
    t.string "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "git_hash"
    t.integer "publication_id"
  end

  create_table "communities", force: :cascade do |t|
    t.string "name"
    t.string "friendly_name"
    t.integer "members"
    t.integer "admins"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "board_id"
    t.integer "publication_id"
    t.integer "end_user_id"
  end

  create_table "communities_admins", id: false, force: :cascade do |t|
    t.integer "community_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communities_members", id: false, force: :cascade do |t|
    t.integer "community_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "decrees", force: :cascade do |t|
    t.string "action"
    t.decimal "trigger", precision: 5, scale: 2
    t.string "choices"
    t.integer "board_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "tally_method"
  end

  create_table "emailers", force: :cascade do |t|
    t.integer "board_id"
    t.integer "user_id"
    t.text "extra_addresses"
    t.string "when_to_send"
    t.boolean "include_document"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "send_to_owner"
    t.boolean "send_to_all_board_members", default: false
    t.boolean "include_comments", default: false
    t.string "subject"
  end

  create_table "emailers_users", id: false, force: :cascade do |t|
    t.integer "emailer_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["emailer_id", "user_id"], name: "index_emailers_users_on_emailer_id_and_user_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "target_id"
    t.string "target_type"
  end

  create_table "identifiers", force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "publication_id"
    t.string "alternate_name"
    t.boolean "modified", default: false
    t.string "title"
    t.string "status", default: "editing"
    t.integer "board_id"
  end

  create_table "publications", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "branch"
    t.string "status", default: "editing"
    t.integer "creator_id"
    t.string "creator_type"
    t.integer "parent_id"
    t.integer "community_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "user_identifiers", force: :cascade do |t|
    t.string "identifier"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "has_repository", default: false
    t.string "language_prefs"
    t.boolean "admin"
    t.boolean "developer"
    t.string "affiliation"
    t.string "email"
    t.integer "emailer_id"
    t.string "full_name"
    t.boolean "is_community_master_admin", default: false
    t.boolean "is_master_admin", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.string "choice"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "publication_id"
    t.integer "identifier_id"
    t.integer "board_id"
  end

end
