class AddMasterToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :master_article_id, :integer
  end

  def self.down
  	remove_column :articles, :master_article_id
  end
end
