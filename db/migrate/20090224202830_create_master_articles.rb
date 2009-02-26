class CreateMasterArticles < ActiveRecord::Migration
  def self.up
    create_table :master_articles do |t|
      t.integer :article_id
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :master_articles
  end
end
