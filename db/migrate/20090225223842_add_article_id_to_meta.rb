class AddArticleIdToMeta < ActiveRecord::Migration
  def self.up
    add_column :metas, :article_id, :integer
  end

  def self.down
  	remove_column :metas, :article_id
  end
end
