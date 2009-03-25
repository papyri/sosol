class AddFinalizerToBoard < ActiveRecord::Migration
  def self.up
    add_column :boards, :finalizer_user_id, :integer
  end

  def self.down
    remove_column :boards, :finalizer_user_id
  end
end
