class FixPublicationIdLimitInCommments < ActiveRecord::Migration
 def self.up	
	change_column :comments, :publication_id, :integer, :limit => nil
 end

 def self.down
	change_column :comments, :publication_id, :integer, :limit => 255
 end
end
