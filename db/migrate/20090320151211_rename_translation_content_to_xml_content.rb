class RenameTranslationContentToXmlContent < ActiveRecord::Migration
  def self.up
    rename_column :translations, :content, :epidoc
  end

  def self.down
  	rename_column :translations, :epidoc, :content
  end
end
