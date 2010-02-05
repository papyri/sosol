class AddIncludeCommentsToEmailer < ActiveRecord::Migration
  def self.up
    add_column :emailers, :include_comments, :boolean, :default => false
  end

  def self.down
    remove_column :emailers, :include_comments
  end
end
