class AddFieldsToMeta < ActiveRecord::Migration
  def self.up
		add_column :metas, :material, :tstring
		add_column :metas, :bl, :tstring
		add_column :metas, :tm_nr, :tstring
		add_column :metas, :content, :tstring
		add_column :metas, :provenance_ancient_findspot, :tstring
		add_column :metas, :provenance_nome, :tstring
		add_column :metas, :provenance_ancient_region, :tstring
		add_column :metas, :other_publications, :tstring
		add_column :metas, :translations, :tstring
		add_column :metas, :illustrations, :tstring
		
		add_column :metas, :mentioned_dates, :tstring

		remove_column :metas, :provenance
		remove_column :metas, :language
		remove_column :metas, :subject
  end

  def self.down
  
  	remove_column :metas, :material
		remove_column :metas, :bl
		remove_column :metas, :tm_nr
		remove_column :metas, :content
		remove_column :metas, :provenance_ancient_findspot
		remove_column :metas, :provenance_nome
		remove_column :metas, :provenance_ancient_region
		remove_column :metas, :other_publications
		remove_column :metas, :translations
		remove_column :metas, :illustrations		
		remove_column :metas, :mentioned_dates

		add_column :metas, :provenance, :tstring
		add_column :metas, :language, :tstring
		add_column :metas, :subject, :tstring
  
  end
end
