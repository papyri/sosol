class AddSendToOwnerToEmailer < ActiveRecord::Migration
  def self.up
  	add_column :emailers, :send_to_owner, :boolean
  end

  def self.down
  	remove_column :emailers, :send_to_owner
  end
end
