class CreateTranslationContents < ActiveRecord::Migration
  def self.up
    create_table :translation_contents do |t|
      t.string :content
      t.integer :translation_id
      t.string :language

      t.timestamps
    end
  end

  def self.down
    drop_table :translation_contents
  end
end
