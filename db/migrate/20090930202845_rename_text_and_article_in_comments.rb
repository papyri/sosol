class RenameTextAndArticleInComments < ActiveRecord::Migration[4.2]
  def self.up
    	rename_column :comments, :text, :comment
    	rename_column :comments, :article_id, :identifier_id
  end

  def self.down
    	rename_column :comments, :comment, :text
    	rename_column :comments, :identifier_id, :article_id
  end
end
