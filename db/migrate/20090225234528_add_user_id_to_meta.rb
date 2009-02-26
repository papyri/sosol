class AddUserIdToMeta < ActiveRecord::Migration
  def self.up
    add_column :metas, :user_id, :integer
  end

  def self.down
  	remove_column :metas, :user_id
  end
end

