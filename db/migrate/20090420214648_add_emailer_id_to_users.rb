class AddEmailerIdToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :emailer_id, :integer
  end

  def self.down
    remove_column :users, :emailer_id
  end
end
