class ChangeCommentsPublicationIdToInt < ActiveRecord::Migration[4.2]
  def self.up
    change_column :comments, :publication_id, :integer
  end

  def self.down
    change_column :comments, :publication_id, :string
  end
end
