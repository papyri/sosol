class ChangeCommentsPublicationIdToInt < ActiveRecord::Migration
  def self.up
    change_column :comments, :publication_id, :integer
  end

  def self.down
    change_column :comments, :publication_id, :string
  end
end
