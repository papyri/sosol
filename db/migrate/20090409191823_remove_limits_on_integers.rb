class RemoveLimitsOnIntegers < ActiveRecord::Migration
  def self.up
	
	change_column :boards_users, :board_id, :integer, :limit => nil

	change_column :votes, :user_id, :integer, :limit => nil

  end

  def self.down

	change_column :boards_users, :board_id, :integer, :limit => 255

	change_column :votes, :user_id, :integer, :limit => 255

  end
end
