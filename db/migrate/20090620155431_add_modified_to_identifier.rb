class AddModifiedToIdentifier < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :modified, :boolean, :default => false
  end

  def self.down
    remove_column :identifiers, :modified
  end
end
