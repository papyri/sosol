# frozen_string_literal: true

class CreateIndexForUsersEmailers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :emailers_users, id: false do |t|
      t.string :emailer_id
      t.integer :user_id

      t.timestamps null: true
    end

    add_index :emailers_users, %i[emailer_id user_id], unique: true
  end

  def self.down
    drop_table :emailers_users
  end
end
