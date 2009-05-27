class AddTranslationContentIdToTranslations < ActiveRecord::Migration
  def self.up
    add_column :translations, :translation_content_id, :integer
  end

  def self.down
    remove_column :translations, :translation_content_id
  end
end
