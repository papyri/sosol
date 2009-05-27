class AddUserIdToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :owner_id, :integer
    add_column :publications, :owner_type, :string
  end

  def self.down
    remove_column :publications, :owner_id
    remove_column :publications, :owner_type
  end
end
