class CreateCommunities < ActiveRecord::Migration
  def self.up
    create_table :communities do |t|
      t.string :name
      t.string :friendly_name
      t.integer :members
      t.integer :admins
      t.string :description

      t.timestamps, null: true
    end
  end

  def self.down
    drop_table :communities
  end
end
