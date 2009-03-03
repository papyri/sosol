class AddStatusToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :status, :string
  end

  def self.down
    remove_column :articles, :status
  end
end
