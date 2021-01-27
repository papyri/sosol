class CreateBoards < ActiveRecord::Migration
  def self.up
    create_table :boards do |t|
      t.string :title
      t.string :category
      t.integer :user_id
      t.integer :decree_id
      # t.integer :article_id

      t.timestamps, null: true
    end
  end

  def self.down
    drop_table :boards
  end
end
