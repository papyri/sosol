class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.string :text
      t.integer :user_id
      t.integer :article_id
      t.string :reason

      t.timestamps, null: true
    end
  end

  def self.down
    drop_table :comments
  end
end
