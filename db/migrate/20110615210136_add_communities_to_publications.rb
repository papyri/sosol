class AddCommunitiesToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :community_id, :integer
    add_column :communities, :publication_id, :integer
  end

  def self.down
    remove_column :publications, :community_id
    remove_column :communities, :publication_id
  end
end
