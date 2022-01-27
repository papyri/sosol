# frozen_string_literal: true

class AddPublicationToComments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :comments, :publication_id, :string
  end

  def self.down
    remove_column :comments, :publication_id, :string
  end
end
