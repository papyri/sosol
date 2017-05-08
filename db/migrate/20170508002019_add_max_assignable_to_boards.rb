class AddMaxAssignableToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :max_assignable, :integer, :default => 0
  end
end
