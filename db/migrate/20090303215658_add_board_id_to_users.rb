class AddBoardIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :board_id, :integer
  end

  def self.down
    remove_column :users, :board_id
  end
end
