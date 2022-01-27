# frozen_string_literal: true

class AddModifiedToIdentifier < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :modified, :boolean, default: false
  end

  def self.down
    remove_column :identifiers, :modified
  end
end
