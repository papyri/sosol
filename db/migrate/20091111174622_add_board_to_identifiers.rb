# frozen_string_literal: true

class AddBoardToIdentifiers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :board_id, :integer
  end

  def self.down
    remove_column :identifiers, :board_id
  end
end
