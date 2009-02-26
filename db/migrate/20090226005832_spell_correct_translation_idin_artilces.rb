class SpellCorrectTranslationIdinArtilces < ActiveRecord::Migration
  def self.up
    rename_column :articles, :trascription_id, :transcription_id
  end

  def self.down
    rename_column :articles, :transcription_id, :trascription_id
  end
end
