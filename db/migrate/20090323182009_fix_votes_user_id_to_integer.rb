class FixVotesUserIdToInteger < ActiveRecord::Migration
  def self.up
    change_column :votes, :user_id, :integer
  end

  def self.down
  	change_column :votes, :user_id, :string
  end
end
