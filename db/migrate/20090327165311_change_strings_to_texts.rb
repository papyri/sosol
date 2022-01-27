class ChangeStringsToTexts < ActiveRecord::Migration[4.2]
  def self.up
    change_column :comments, :text, :text

    # change_column :transcriptions, :content, :text
    # change_column :transcriptions, :leiden, :text
    #
    # change_column :translation_contents, :content, :text
    #
    # change_column :translations, :epidoc, :text
  end

  def self.down
    change_column :comments, :text, :string

    # change_column :transcriptions, :content, :string
    # change_column :transcriptions, :leiden, :string
    #
    # change_column :translation_contents, :content, :string
    #
    # change_column :translations, :epidoc, :string
  end
end
