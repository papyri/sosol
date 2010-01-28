class AddBoardIdToVote < ActiveRecord::Migration
  def self.up
    add_column :votes, :board_id, :integer
  end

  def self.down
    remove_column :votes, :board_id
  end
end
