class AddStatusToIdentifiers < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :status, :string, :default => "editing"
  end

  def self.down
    remove_column :identifiers, :status
  end
end
