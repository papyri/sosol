class AddFlagsToTranslation < ActiveRecord::Migration
  def self.up
  	add_column :translations, :xml_to_translations_ok, :boolean
  	add_column :translations, :translations_to_xml_ok, :boolean
  end

  def self.down
  	remove_column :translations, :xml_to_translations_ok
  	remove_column :translations, :translations_to_xml_ok
  end
end
