# frozen_string_literal: true

class CreateCommunityMembers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :communities_members, id: false do |t|
      t.integer :community_id
      t.integer :user_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :communities_members
  end
end
