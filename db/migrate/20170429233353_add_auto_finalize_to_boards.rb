class AddAutoFinalizeToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :auto_finalize, :boolean, :default => false
  end
end
