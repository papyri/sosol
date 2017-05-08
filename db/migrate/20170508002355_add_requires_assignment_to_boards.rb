class AddRequiresAssignmentToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :requires_assignment, :boolean, :default => false
  end
end
