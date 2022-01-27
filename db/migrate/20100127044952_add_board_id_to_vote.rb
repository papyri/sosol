# frozen_string_literal: true

class AddBoardIdToVote < ActiveRecord::Migration[4.2]
  def self.up
    add_column :votes, :board_id, :integer
  end

  def self.down
    remove_column :votes, :board_id
  end
end
