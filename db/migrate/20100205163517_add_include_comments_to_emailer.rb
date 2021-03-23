class AddIncludeCommentsToEmailer < ActiveRecord::Migration[4.2]
  def self.up
    add_column :emailers, :include_comments, :boolean, :default => false
  end

  def self.down
    remove_column :emailers, :include_comments
  end
end
