# frozen_string_literal: true

class AddStatusToIdentifiers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :identifiers, :status, :string, default: 'editing'
  end

  def self.down
    remove_column :identifiers, :status
  end
end
