class AddLeidenToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :leiden, :text
  end

  def self.down
    remove_column :documents, :leiden
  end
end
