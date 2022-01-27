# frozen_string_literal: true

class AddBranchToPublication < ActiveRecord::Migration[4.2]
  def self.up
    add_column :publications, :branch, :string
  end

  def self.down
    remove_column :publications, :branch
  end
end
