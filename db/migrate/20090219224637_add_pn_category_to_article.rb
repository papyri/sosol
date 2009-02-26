class AddPnCategoryToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :pn, :string
    add_column :articles, :category, :string
  end

  def self.down
    remove_column :articles, :pn
    remove_column :articles, :category
  end
end
