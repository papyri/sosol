# frozen_string_literal: true

class AddOwnerIdToPublication < ActiveRecord::Migration[4.2]
  def self.up
    add_column :publications, :owner_id, :integer
    add_column :publications, :owner_type, :string
  end

  def self.down
    remove_column :publications, :owner_id
    remove_column :publications, :owner_type
  end
end
