class AddPublicationToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :publication_id, :string
  end

  def self.down
    remove_column :comments, :publication_id, :string
  end
end
