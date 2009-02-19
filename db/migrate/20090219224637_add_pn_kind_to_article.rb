class AddPnKindToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :pn, :string
  end

  def self.down
    remove_column :articles, :pn
  end
end
