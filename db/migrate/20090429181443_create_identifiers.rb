class CreateIdentifiers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :identifiers do |t|
      t.string :name
      t.string :type

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :identifiers
  end
end
