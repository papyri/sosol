# frozen_string_literal: true

class AddFinalizerToBoard < ActiveRecord::Migration[4.2]
  def self.up
    add_column :boards, :finalizer_user_id, :integer
  end

  def self.down
    remove_column :boards, :finalizer_user_id
  end
end
