class AddAlternateNameToIdentifier < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :alternate_name, :string
  end

  def self.down
    remove_column :identifiers, :alternate_name
  end
end
