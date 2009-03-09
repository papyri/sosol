class AddTranslationContentIdToTranslations < ActiveRecord::Migration
  def self.up
    add_column :translation_contents, :translation_id, :integer
  end

  def self.down
    remove_column :translation_contents, :translation_id
  end
end
