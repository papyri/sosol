class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.string :choice
      t.string :user_id
      # t.integer :article_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :votes
  end
end
