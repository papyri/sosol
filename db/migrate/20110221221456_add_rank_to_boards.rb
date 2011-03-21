class AddRankToBoards < ActiveRecord::Migration
  def self.up
    add_column :boards, :rank, :decimal
  end

  def self.down
    remove_column :boards, :rank
  end
end
