class FixBoardUsersId < ActiveRecord::Migration[4.2]
  def self.up
      change_column :boards_users, :board_id, :integer
  end

  def self.down
  		change_column :boards_users, :board_id, :string  
  end
end
