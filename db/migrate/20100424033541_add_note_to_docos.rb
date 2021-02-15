class AddNoteToDocos < ActiveRecord::Migration[4.2]
  def self.up
    add_column :docos, :note, :text
  end

  def self.down
    remove_column :docos, :note
  end
end
