class AddAllowsAssignmentToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :allows_assignment, :integer, :default => 0
  end
end
