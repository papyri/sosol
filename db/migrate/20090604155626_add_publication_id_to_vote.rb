# frozen_string_literal: true

class AddPublicationIdToVote < ActiveRecord::Migration[4.2]
  def self.up
    add_column :votes, :publication_id, :integer
  end

  def self.down
    remove_column :votes, :publication_id
  end
end
