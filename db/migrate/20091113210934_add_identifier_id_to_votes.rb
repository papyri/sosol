class AddIdentifierIdToVotes < ActiveRecord::Migration
  def self.up
    add_column :votes, :identifier_id, :integer
  end

  def self.down
   remove_column :votes, :identifier_id
  end
end
