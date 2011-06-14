class CreateCommunityAdmins < ActiveRecord::Migration
  def self.up
    create_table :communities_admins do |t|
      t.integer :community_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :community_admins
  end
end
