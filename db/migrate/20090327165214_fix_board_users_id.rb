# frozen_string_literal: true

class FixBoardUsersId < ActiveRecord::Migration[4.2]
  def self.up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :boards_users, :board_id, "integer using nullif(board_id, '')::int"
    else
      change_column :boards_users, :board_id, :integer
    end
  end

  def self.down
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :boards_users, :board_id, "string using nullif(board_id, '')::string"
    else
      change_column :boards_users, :board_id, :string
    end
  end
end
