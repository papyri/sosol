class AddEndUserToCommunities < ActiveRecord::Migration
  def self.up
    add_column :communities, :end_user_id, :integer
  end

  def self.down
    remove_column :communities, :end_user_id
  end
end

