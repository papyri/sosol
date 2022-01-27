# frozen_string_literal: true

class AddBoardIdToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :board_id, :integer
  end

  def self.down
    remove_column :users, :board_id
  end
end
