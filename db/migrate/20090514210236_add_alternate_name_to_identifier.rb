class AddAlternateNameToIdentifier < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :alternate_name, :string
  end

  def self.down
    remove_column :identifiers, :alternate_name
  end
end
