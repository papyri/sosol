class AddRankToBoards < ActiveRecord::Migration[4.2]
  def self.up
    add_column :boards, :rank, :decimal
  end

  def self.down
    remove_column :boards, :rank
  end
end
