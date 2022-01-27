# frozen_string_literal: true

class CreateVotes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :votes do |t|
      t.string :choice
      t.string :user_id
      # t.integer :article_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :votes
  end
end
