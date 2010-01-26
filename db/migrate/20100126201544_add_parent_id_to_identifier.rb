class AddParentIdToIdentifier < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :parent_id, :integer
  end

  def self.down
    remove_column :identifiers, :parent_id
  end
end
