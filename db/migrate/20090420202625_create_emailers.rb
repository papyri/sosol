class CreateEmailers < ActiveRecord::Migration
  def self.up
    create_table :emailers do |t|
      t.integer :board_id
      t.integer :user_id
      t.text :extra_addresses
      t.string :status
      t.boolean :include_document
      t.text :message

      t.timestamps, null: true
    end
  end

  def self.down
    drop_table :emailers
  end
end
