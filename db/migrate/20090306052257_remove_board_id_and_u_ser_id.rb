class RemoveBoardIdAndUSerId < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :users, :board_id
    remove_column :boards, :user_id
  end

  def self.down
    add_column :users, :board_id, :integer
    add_column :boards, :user_id, :integer
  end
end
