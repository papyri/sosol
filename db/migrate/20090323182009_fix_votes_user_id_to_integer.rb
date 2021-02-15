class FixVotesUserIdToInteger < ActiveRecord::Migration[4.2]
  def self.up
    change_column :votes, :user_id, :integer
  end

  def self.down
  	change_column :votes, :user_id, :string
  end
end
