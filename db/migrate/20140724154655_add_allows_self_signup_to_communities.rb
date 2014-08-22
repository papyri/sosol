class AddAllowsSelfSignupToCommunities < ActiveRecord::Migration
  def self.up
    add_column :communities, :allows_self_signup, :boolean, :default => false
  end

  def self.down
    remove_column :communities, :allows_self_signup
  end
end
