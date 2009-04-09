class ChangeIdsFromStringsToIntegers < ActiveRecord::Migration
  def self.up
  	change_column :master_articles, :user_id, :integer
  	change_column :master_articles, :comment_id, :integer
  end

  def self.down
  	change_column :master_articles, :user_id, :string
  	change_column :master_articles, :comment_id, :string
  end
end
