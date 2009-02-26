class AddUserToMasterArticle < ActiveRecord::Migration
  def self.up
    add_column :master_articles, :user_id, :string
    add_column :master_articles, :comment_id, :string
  end

  def self.down
  remove_column :master_articles, :user_id
  remove_column :master_articles, :comment_id
  end
end
