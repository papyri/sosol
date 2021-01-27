class CreateCommunityAdmins < ActiveRecord::Migration
  def self.up
    create_table :communities_admins , :id => false do |t|
      t.integer :community_id
      t.integer :user_id

      t.timestamps, null: true
    end
  end

  def self.down
    drop_table :communities_admins
  end
end
