class FixBoardUsersId < ActiveRecord::Migration
  def self.up
      change_column :boards_users, :board_id, :integer
  end

  def self.down
  		change_column :boards_users, :board_id, :string  
  end
end
