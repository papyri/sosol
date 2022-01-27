# frozen_string_literal: true

class AddOwnerTargetToEvent < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :owner_id, :integer
    add_column :events, :owner_type, :string
    add_column :events, :target_id, :integer
    add_column :events, :target_type, :string
  end

  def self.down
    remove_column :events, :target_type
    remove_column :events, :target_id
    remove_column :events, :owner_type
    remove_column :events, :owner_id
  end
end
