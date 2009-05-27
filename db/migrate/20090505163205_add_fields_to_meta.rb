class AddFieldsToMeta < ActiveRecord::Migration
  def self.up
		add_column :metas, :material, :string
		add_column :metas, :bl, :string
		add_column :metas, :tm_nr, :string
		add_column :metas, :content, :string
		add_column :metas, :provenance_ancient_findspot, :string
		add_column :metas, :provenance_nome, :string
		add_column :metas, :provenance_ancient_region, :string
		add_column :metas, :other_publications, :string
		add_column :metas, :translations, :string
		add_column :metas, :illustrations, :string
		
		add_column :metas, :mentioned_dates, :string

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

		add_column :metas, :provenance, :string
		add_column :metas, :language, :string
		add_column :metas, :subject, :string
  
  end
end
