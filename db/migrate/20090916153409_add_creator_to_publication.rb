class AddCreatorToPublication < ActiveRecord::Migration[4.2]
  def self.up
    add_column :publications, :creator_id, :integer
    add_column :publications, :creator_type, :string
  end

  def self.down
    remove_column :publications, :creator_type
    remove_column :publications, :creator_id
  end
end
