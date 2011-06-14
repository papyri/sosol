class CreateCommunities < ActiveRecord::Migration
  def self.up
    create_table :communities do |t|
      t.string :name
      t.string :friendly_name
      t.string :abbreviation
      t.integer :members
      t.integer :admins
      t.string :description
      t.string :logo

      t.timestamps
    end
  end

  def self.down
    drop_table :communities
  end
end
