# frozen_string_literal: true

class AddStatusToPublication < ActiveRecord::Migration[4.2]
  def self.up
    add_column :publications, :status, :string
  end

  def self.down
    remove_column :publications, :status
  end
end
