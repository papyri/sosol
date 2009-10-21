class AddTitleToIdentifiers < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :title, :string
  end

  def self.down
    remove_column :identifiers, :title
  end
end
