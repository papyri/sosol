class AddPublicationIdToIdentifier < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :publication_id, :integer
  end

  def self.down
    remove_column :identifiers, :publication_id
  end
end
