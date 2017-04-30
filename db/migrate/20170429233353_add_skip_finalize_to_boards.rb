class AddSkipFinalizeToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :skip_finalize, :boolean, :default => false
  end
end
