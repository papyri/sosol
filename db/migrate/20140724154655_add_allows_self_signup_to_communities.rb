class AddAllowsSelfSignupToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :allows_self_signup, :boolean, :default => false
  end
end
