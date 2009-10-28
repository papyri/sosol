class AddGithashToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :git_hash, :string
  end

  def self.down
    remove_column :comments, :git_hash, :string
  end
end
  
