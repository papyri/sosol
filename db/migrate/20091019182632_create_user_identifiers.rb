class CreateUserIdentifiers < ActiveRecord::Migration
  def self.up
    create_table :user_identifiers do |t|
      t.string :identifier
      t.integer :user_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :user_identifiers
  end
end
