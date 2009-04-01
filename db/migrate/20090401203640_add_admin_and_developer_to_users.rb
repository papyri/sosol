class AddAdminAndDeveloperToUsers < ActiveRecord::Migration
  def self.up
	add_column :users, :admin, :boolean
	add_column :users, :developer, :boolean
  end

  def self.down
	remove_column :users, :admin
	remove_column :users, :developer
  end
end
