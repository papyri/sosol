class AddBoardsCommunityKeys < ActiveRecord::Migration
  def self.up
    add_column :boards, :community_id, :integer
    add_column :communities, :board_id, :integer
  end

  def self.down
    remove_column :boards, :community_id
    remvoe_column :communities, :board_id
  end
end
