class RemoveAllowsAssignmentFromCommunities < ActiveRecord::Migration
  def up
    remove_column :communities, :allows_assignment
  end

  def down
    add_column :communities, :allows_assignment, :integer, :default => 0
  end
end
