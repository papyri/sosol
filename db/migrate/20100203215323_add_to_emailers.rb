class AddToEmailers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :emailers, :send_to_all_board_members, :boolean, :default => false
  end

  def self.down
    remove_column :emailers, :send_to_all_board_members
  end
end
