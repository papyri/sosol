class RenameDocument < ActiveRecord::Migration
  def self.up
	rename_table :documents, :articles
  end

  def self.down
	rename_table :articles, :documents
  end
end
