class ChangeCommentToText < ActiveRecord::Migration
  def self.up
    change_column :comments, :comment, :text, :limit => 2047
  end

  def self.down
    change_column :comments, :comment, :string, :limit => 255
  end
end
