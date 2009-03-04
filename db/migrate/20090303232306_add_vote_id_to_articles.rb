class AddVoteIdToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :vote_id, :integer
  end

  def self.down
    remove_column :articles, :vote_id
  end
end
