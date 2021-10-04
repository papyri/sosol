class FixBoardUsersId < ActiveRecord::Migration[4.2]
  def self.up
    if activerecord::base.connection.adapter_name == 'postgresql'
      change_column :boards_users, :board_id, "integer using nullif(board_id, '')::int"
    else
      change_column :boards_users, :board_id, :integer
    end
  end

  def self.down
    if activerecord::base.connection.adapter_name == 'postgresql'
      change_column :boards_users, :board_id, "string using nullif(board_id, '')::string"
    else
  		change_column :boards_users, :board_id, :string  
    end
  end
end
