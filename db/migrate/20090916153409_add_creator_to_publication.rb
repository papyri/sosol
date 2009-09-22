class AddCreatorToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :creator_id, :integer
    add_column :publications, :creator_type, :string
  end

  def self.down
    remove_column :publications, :creator_type
    remove_column :publications, :creator_id
  end
end
