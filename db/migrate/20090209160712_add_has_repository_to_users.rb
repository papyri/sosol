# frozen_string_literal: true

class AddHasRepositoryToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :has_repository, :boolean, default: false
  end

  def self.down
    remove_column :users, :has_repository
  end
end
