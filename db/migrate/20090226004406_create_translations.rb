class CreateTranslations < ActiveRecord::Migration
  def self.up
    create_table :translations do |t|
      t.string :content
      t.string :language
      t.integer :user_id
      t.integer :article_id

      t.timestamps
    end
  end

  def self.down
    drop_table :translations
  end
end
