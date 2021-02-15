class AddBoardsCommunityKeys < ActiveRecord::Migration[4.2]
  def self.up
    add_column :boards, :community_id, :integer
    add_column :communities, :board_id, :integer
  end

  def self.down
    remove_column :boards, :community_id
    remove_column :communities, :board_id
  end
end
