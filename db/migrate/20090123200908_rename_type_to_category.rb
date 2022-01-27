class RenameTypeToCategory < ActiveRecord::Migration[4.2]
  def self.up
    rename_column 'events', 'type', 'category'
  end

  def self.down
    rename_column 'events', 'category', 'type'
  end
end
