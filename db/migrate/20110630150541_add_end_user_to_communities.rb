class AddEndUserToCommunities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :communities, :end_user_id, :integer
  end

  def self.down
    remove_column :communities, :end_user_id
  end
end

