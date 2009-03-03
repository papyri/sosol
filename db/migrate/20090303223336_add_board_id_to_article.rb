class AddBoardIdToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :board_id, :integer
  end

  def self.down
    remove_column :articles, :board_id
  end
end
