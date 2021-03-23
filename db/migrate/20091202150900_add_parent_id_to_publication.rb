class AddParentIdToPublication < ActiveRecord::Migration[4.2]
  def self.up
    add_column :publications, :parent_id, :integer
  end

  def self.down
    remove_column :publications, :parent_id
  end
end
