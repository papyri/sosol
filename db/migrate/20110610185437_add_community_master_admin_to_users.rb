# frozen_string_literal: true

class AddCommunityMasterAdminToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :is_community_master_admin, :boolean, default: false
  end

  def self.down
    remove_column :users, :is_community_master_admin
  end
end
