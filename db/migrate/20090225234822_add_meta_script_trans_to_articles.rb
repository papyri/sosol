class AddMetaScriptTransToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :meta_id, :integer
    add_column :articles, :trascription_id, :integer
    add_column :articles, :translation_id, :integer
  end

  def self.down
    remove_column :articles, :meta_id
    remove_column :articles, :trascription_id
    remove_column :articles, :translation_id
  end
end
