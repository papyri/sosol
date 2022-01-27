# frozen_string_literal: true

class AddPublicationIdToIdentifier < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :publication_id, :integer
  end

  def self.down
    remove_column :identifiers, :publication_id
  end
end
