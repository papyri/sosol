class AddBoardToIdentifiers < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :board_id, :integer
  end

  def self.down
    remove_column :identifiers, :board_id
  end
end
