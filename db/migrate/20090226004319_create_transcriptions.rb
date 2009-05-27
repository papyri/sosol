class CreateTranscriptions < ActiveRecord::Migration
  def self.up
    create_table :transcriptions do |t|
      t.string :content
      t.string :leiden
      t.integer :user_id
      t.integer :article_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transcriptions
  end
end
