# frozen_string_literal: true

class AddSendToOwnerToEmailer < ActiveRecord::Migration[4.2]
  def self.up
    add_column :emailers, :send_to_owner, :boolean
  end

  def self.down
    remove_column :emailers, :send_to_owner
  end
end
