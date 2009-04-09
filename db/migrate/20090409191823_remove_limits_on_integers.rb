class RemoveLimitsOnIntegers < ActiveRecord::Migration
  def self.up
	
	change_column :boards_users, :board_id, :integer, :limit => nil

	change_column :comments, :text, :text, :limit => nil

	change_column :master_articles, :user_id, :integer, :limit => nil
	change_column :master_articles, :comment_id, :integer, :limit => nil

	change_column :transcriptions, :content, :text, :limit => nil
	change_column :transcriptions, :leiden, :text, :limit => nil

	change_column :translation_contents, :content, :text, :limit => nil
	
	change_column :translations, :epidoc, :text, :limit => nil

	change_column :votes, :user_id, :integer, :limit => nil

  end

  def self.down

	change_column :boards_users, :board_id, :integer, :limit => 255

	change_column :comments, :text, :text, :limit => 255

	change_column :master_articles, :user_id, :integer, :limit => 255
	change_column :master_articles, :comment_id, :integer, :limit => 255

	change_column :transcriptions, :content, :text, :limit => 255
	change_column :transcriptions, :leiden, :text, :limit => 255

	change_column :translation_contents, :content, :text, :limit => 255
	
	change_column :translations, :epidoc, :text, :limit => 255

	change_column :votes, :user_id, :integer, :limit => 255

  end
end
