class AddTitleToIdentifiers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :title, :string
  end

  def self.down
    remove_column :identifiers, :title
  end
end
