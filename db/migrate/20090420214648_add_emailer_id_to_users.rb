class AddEmailerIdToUsers < ActiveRecord::Migration
  def self.up
  	add_column :users, :emailer_id, :integer
  end

  def self.down
  	remove_column :users, :emailer_id
  end
end
