class AddHasRepositoryToUsers < ActiveRecord::Migration
  def self.up
		add_column :users, :has_repository, :boolean, :default => false
  end

  def self.down
		remove_column :users, :has_repository
  end
end
